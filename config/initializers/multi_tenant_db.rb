if defined?(Rails::Server)
  ActiveSupport.on_load(:active_record) do
    begin
      Tenant.find_each(&:register_database_configurations)
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      puts 'Warning: can not load tenant databases'
    end
  end

  Rails.application.configure do
    config.active_record.shard_selector = { lock: true }
    config.active_record.shard_resolver = ->(request) {
      tenant = Tenant.find_by(subdomain: request.subdomain)
      tenant&.shard || :default
    }
  end
end
