class AddCanRoam < ActiveRecord::Migration
  def change
    add_column :users, :can_roam, :boolean, :default => false
  end
end
