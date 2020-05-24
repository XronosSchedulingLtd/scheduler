class AddRoleToMembership < ActiveRecord::Migration[4.2]
  def change
    add_column :memberships, :role_id, :integer
  end
end
