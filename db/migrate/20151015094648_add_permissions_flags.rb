class AddPermissionsFlags < ActiveRecord::Migration
  def change
    add_column :events, :complete,    :boolean, :default => true
    add_column :events, :constrained, :boolean, :default => false

    add_index :events, :complete

    add_column :commitments, :tentative,    :boolean, :default => false
    add_column :commitments, :rejected,     :boolean, :default => false
    add_column :commitments, :constraining, :boolean, :default => false

    add_index :commitments, :tentative
    add_index :commitments, :constraining

    add_column :elements, :owned, :boolean, :default => false

    add_column :users, :element_owner, :boolean, :default => false

  end
end
