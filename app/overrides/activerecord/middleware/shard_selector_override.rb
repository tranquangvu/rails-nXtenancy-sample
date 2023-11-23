module ActiveRecord
  module Middleware
    class ShardSelector
      # Switch shard for `TenantedRecord` only instead of `ActiveRecord::Base`
      def set_shard(shard, &block)
        TenantedRecord.connected_to(shard: shard.to_sym) do
          TenantedRecord.prohibit_shard_swapping(options.fetch(:lock, true), &block)
        end
      end
    end
  end
end
