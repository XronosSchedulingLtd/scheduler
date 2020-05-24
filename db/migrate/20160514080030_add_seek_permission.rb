class AddSeekPermission < ActiveRecord::Migration[4.2]
  def change
    add_column :concerns, :seek_permission,   :boolean, :default => false
  end
end
