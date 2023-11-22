namespace :db do
  namespace :rollback do
    task tenants: :load_config do
      Tenant.find_each do |tenant|
        step = ENV['STEP'] ? ENV['STEP'].to_i : 1
        name = tenant.subdomain

        ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection_for_each(env: Rails.env, name: name) do |conn|
          conn.migration_context.rollback(step)
        end

        Rake::Task['db:_dump'].invoke
      end
    end
  end
end
