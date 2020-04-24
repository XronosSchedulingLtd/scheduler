class ReworkLocationAliases < ActiveRecord::Migration[4.2]
  def change
    add_column :locationaliases, :display,  :boolean, :default => false
    add_column :locationaliases, :friendly, :boolean, :default => false
    remove_column :locations, :short_name
  end
end
