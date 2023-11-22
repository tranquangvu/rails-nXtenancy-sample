ActiveSupport.on_load(:active_record) do
  begin
    Tenant.find_each do |tenant|
      dbconf = ActiveRecord::DatabaseConfigurations::HashConfig.new(
        Rails.env,
        tenant.shard,
        tenant.dbc.merge({ migrations_paths: 'db/tenants_migrate', schema_dump: 'tenants_schema.sql' })
      )
      dbconfs = ActiveRecord::Base.configurations
      dbconfs.configurations << dbconf
    end
  rescue ActiveRecord::ActiveRecordError
    nil # skip errors when no tenants created
  end
end
