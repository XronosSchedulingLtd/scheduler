class AddEditingMembershipsFlag < ActiveRecord::Migration
  def change
    add_column :users, :can_edit_memberships, :boolean, default: false
  end
end
