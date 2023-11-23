class TenantedRecord < ApplicationRecord
  self.abstract_class = true
  self.connection_class = true

  def self.shards_from_tenants
    Tenant.find_each.to_h do |tenant|
      shard = tenant.shard&.to_sym
      [shard, { writing: shard, reading: shard }]
    end
  end

  connects_to shards: shards_from_tenants
end
