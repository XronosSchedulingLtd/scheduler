class AddSeekPermission < ActiveRecord::Migration
  def change
    add_column :concerns, :seek_permission,   :boolean, :default => false
  end
end
