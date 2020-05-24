class AddCanRoam < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_roam, :boolean, :default => false
  end
end
