class Tenant < CentralRecord
  store_accessor :dbc, :adapter, :encoding, :host, :port, :username, :password, :database, :pool, prefix: true

  validates :subdomain, presence: true, uniqueness: { case_sensitive: false }
  validates :shard, presence: true, uniqueness: { case_sensitive: false }
  validates :dbc_host, presence: true
  validates :dbc_port, presence: true
  validates :dbc_username, presence: true
  validates :dbc_database, presence: true
  validates :dbc_pool, presence: true

  before_validation :correct_dbc_values

  private

  def correct_dbc_values
    self.dbc_adapter = 'postgresql'
    self.dbc_encoding = 'unicode'
    self.dbc_port = dbc_port.presence&.to_i || 5432
    self.dbc_pool = 5
  end
end
