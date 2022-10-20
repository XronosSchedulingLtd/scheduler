class AddListRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :concerns, :list_rooms, :boolean, default: false
    add_column :users,    :list_rooms, :boolean, default: false
  end
end
