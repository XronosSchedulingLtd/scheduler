class AddEditingMembershipsFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_edit_memberships, :boolean, default: false
  end
end
