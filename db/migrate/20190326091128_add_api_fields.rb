class AddApiFields < ActiveRecord::Migration
  def change
    add_column :users, :uuid, :string
    add_index  :users, :uuid, unique: true
    add_column :users, :can_api, :boolean, default: false
  end
end
