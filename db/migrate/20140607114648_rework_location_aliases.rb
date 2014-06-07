class ReworkLocationAliases < ActiveRecord::Migration
  def change
    add_column :locationaliases, :display,  :boolean, :default => false
    add_column :locationaliases, :friendly, :boolean, :default => false
    remove_column :locations, :short_name
  end
end
