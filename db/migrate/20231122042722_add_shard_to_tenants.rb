class AddShardToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :shard, :string, null: false, default: ''
  end
end
