class Tenant < CentralRecord
  store_accessor :dbc, :adapter, :encoding, :host, :port,
                 :username, :password, :database, :pool, prefix: true

  # validations
  validates_presence_of :dbc_adapter, :dbc_encoding, :dbc_host, :dbc_port, :dbc_username, :dbc_database, :dbc_pool
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false }
  validates :shard, presence: true, uniqueness: { case_sensitive: false }

  # callbacks
  after_save :setup_new_database_connection

  def db_config
    conf_hash = dbc.merge({ migrations_paths: 'db/tenant_migrate', schema_dump: 'tenant_structure.sql' })
    ActiveRecord::DatabaseConfigurations::HashConfig.new(Rails.env, shard, conf_hash)
  end

  def register_database_configurations
    db_configs = ActiveRecord::Base.configurations
    db_configs.configurations << db_config
  end
end
