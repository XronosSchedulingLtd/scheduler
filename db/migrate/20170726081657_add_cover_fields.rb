class AddCoverFields < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :room_cover_group_element_id, :integer
    add_column :users,    :can_relocate_lessons, :boolean, default: false
  end
end
