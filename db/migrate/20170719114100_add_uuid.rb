class AddUuid < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :uuid, :string
    add_index :elements, :uuid, unique: true
    add_column :settings, :prefer_https, :boolean, default: true
    add_column :settings, :require_uuid, :boolean, default: false
  end
end
