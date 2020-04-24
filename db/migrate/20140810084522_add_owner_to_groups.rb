class AddOwnerToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :owner_id, :integer, :default => nil
    add_index :groups, :owner_id
  end
end
