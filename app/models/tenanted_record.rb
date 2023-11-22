class TenantedRecord < ActiveRecord::Base
  self.abstract_class = true

  class << self
    def shards_form_tenants
      Tenant.all.to_h do |tenant|
        shard = tenant.shard&.to_sym
        [shard, { writing: shard, reading: shard }]
      end
    end
  end

  connects_to shards: shards_form_tenants
end
