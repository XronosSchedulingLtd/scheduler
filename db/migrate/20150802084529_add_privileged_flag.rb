class AddPrivilegedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users,           :privileged, :boolean, :default => false
    add_column :eventcategories, :privileged, :boolean, :default => false
  end
end
