module ActiveRecord
  module Middleware
    class ShardSelector
      # Only model class extends from TenantedRecord (Rails default use ActiveRecord::Base) can switch shards
      def set_shard(shard, &block)
        TenantedRecord.connected_to(shard: shard.to_sym) do
          TenantedRecord.prohibit_shard_swapping(options.fetch(:lock, true), &block)
        end
      end
    end
  end
end
