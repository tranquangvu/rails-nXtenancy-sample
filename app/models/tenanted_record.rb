class TenantedRecord < ApplicationRecord
  self.abstract_class = true
  self.connection_class = true

  class << self
    def load_tenant_shards
      shards = Tenant.find_each.to_h do |tenant|
        shard = tenant.shard&.to_sym
        [shard, { writing: shard, reading: shard }]
      end
      connects_to shards: shards
    end
  end

  load_tenant_shards
end
