class AddOwnerToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :owner_id, :integer, :default => nil
    add_index :groups, :owner_id
  end
end
