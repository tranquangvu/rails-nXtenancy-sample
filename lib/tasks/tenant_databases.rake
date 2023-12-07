tdb_namespace = namespace :tdb do
  task load_config: :environment do
    # Fore set migration path to `db/tenants_migrate`
    ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/tenants_migrate'].to_a

    # Add tenant database configurations
    Tenant.find_each(&:register_database_configurations)
  end

  task check_protected_environments: :load_config do
    ActiveRecord::Tasks::DatabaseTasks.check_protected_environments!
  end

  task abort_if_pending_migrations: :load_config do
    pending_migrations = []
    Tenant.find_each do |tenant|
      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: tenant.shard) do |conn|
        pending_migrations << conn.migration_context.open.pending_migrations
      end
    end
    pending_migrations.flatten!

    if pending_migrations.any?
      puts 'You have pending migrations in tenant databases'
      abort %{Run `bin/rails db:migrate` to update your database then try again.}
    end
  end

  desc 'Create the databases from for the current RAILS_ENV'
  task create: :load_config do
    Tenant.find_each do |tenant|
      ActiveRecord::Tasks::DatabaseTasks.create(tenant.db_config)
    end
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
  task migrate: :load_config do
    db_configs = Tenant.find_each.map(&:db_config)
    mapped_versions = ActiveRecord::Tasks::DatabaseTasks.db_configs_with_versions(db_configs)
    mapped_versions.sort.each do |version, configs|
      configs.each do |config|
        puts "\nShard: #{config.name} - Database: #{config.database}\n"
        ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(config) do
          ActiveRecord::Tasks::DatabaseTasks.migrate(version)
        end
      end
    end
    tdb_namespace['_dump'].invoke
  end
  namespace :migrate do
    desc 'Run the "up" for a given migration VERSION.'
    task up: :load_config do
      raise 'VERSION is required' if !ENV['VERSION'] || ENV['VERSION'].empty?

      Tenant.find_each do |tenant|
        ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: tenant.shard) do |conn|
          ActiveRecord::Tasks::DatabaseTasks.check_target_version
          conn.migration_context.run(:up, ActiveRecord::Tasks::DatabaseTasks.target_version)
        end
      end
      tdb_namespace['_dump'].invoke
    end

    desc 'Run the "down" for a given migration VERSION.'
    task down: :load_config do
      raise 'VERSION is required - To go down one migration, use db:rollback' if !ENV['VERSION'] || ENV['VERSION'].empty?

      Tenant.find_each do |tenant|
        ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: tenant.shard) do |conn|
          ActiveRecord::Tasks::DatabaseTasks.check_target_version
          conn.migration_context.run(:down, ActiveRecord::Tasks::DatabaseTasks.target_version)
        end
      end
      db_namespace['_dump'].invoke
    end

    desc 'Display status of migrations'
    task status: :load_config do
      tenant = Tenant.first
      return unless tenant.present?

      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: tenant.shard) do |conn|
        unless conn.schema_migration.table_exists?
          Kernel.abort 'Schema migrations table does not exist yet.'
        end
        puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
        puts '-' * 50
        conn.migration_context.migrations_status.each do |status, version, name|
          puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"
        end
        puts
      end
    end
  end

  desc 'Roll the schema back to the previous version (specify steps w/ STEP=n).'
  task rollback: :load_config do
    Tenant.find_each do |tenant|
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: tenant.shard) do |conn|
        conn.migration_context.rollback(step)
      end
    end
    db_namespace['_dump'].invoke
  end

  desc 'Drop the databases for the current RAILS_ENV.'
  task drop: [:load_config, :check_protected_environments] do
    Tenant.find_each do |tenant|
      ActiveRecord::Tasks::DatabaseTasks.drop(tenant.db_config)
    end
  end

  task :_dump do
    if ActiveRecord.dump_schema_after_migration
      tdb_namespace['schema:dump'].invoke
    end
    tdb_namespace['_dump'].reenable
  end

  namespace :schema do
    desc 'Create a database schema file (either db/tenants_schema.rb or db/tenants_schema.sql, depending on `ENV["SCHEMA_FORMAT"]` or `config.active_record.schema_format`)'
    task dump: :load_config do
      # Since all tenants share the same schema structure, running dump for the first tenant is sufficient
      if (name = Tenant.first&.shard).present?
        ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: name) do |conn|
          db_config = conn.pool.db_config
          schema_format = ENV.fetch('SCHEMA_FORMAT', ActiveRecord.schema_format).to_sym
          ActiveRecord::Tasks::DatabaseTasks.dump_schema(db_config, schema_format)
        end
      end
      tdb_namespace['schema:dump'].reenable
    end

    desc 'Load a database schema file (either db/tenant_schema.rb or db/tenant_structure.sql, depending on `ENV["SCHEMA_FORMAT"]` or `config.active_record.schema_format`) into the database'
    task load: [:load_config, :check_protected_environments] do
      Tenant.find_each do |tenant|
        db_config = tenant.db_config
        with_temporary_connection(db_config) do
          load_schema(db_config)
        end
      end
    end
  end

  desc 'Load the seed data from db/tenant_seeds.rb'
  task seed: :load_config do
    tdb_namespace['abort_if_pending_migrations'].invoke
    tenant_seed_file = Rails.application.paths['db/tenant_seeds.rb'].existent.first
    run_callbacks(:load_tenant_seed) { load(tenant_seed_file) } if tenant_seed_file
  end

  desc 'Drop and recreate all tenant databases from their schema for the current environment and load the seeds.'
  task reset: ['tdb:drop', 'tdb:setup']

  desc 'Create all tentant databases, load all schemas, and initialize with the seed data (use db:reset to also drop all databases first)'
  task setup: ['tdb:create', :environment, 'tdb:schema:load', 'tdb:seed']
end
