class CreateTenants < ActiveRecord::Migration[7.0]
  def change
    create_table :tenants do |t|
      t.string :subdomain, null: false, index: { unique: true }
      t.jsonb :dbc, null: false, default: {}
      t.timestamps
    end
  end
end
