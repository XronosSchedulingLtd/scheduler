class AddRoleToMembership < ActiveRecord::Migration
  def change
    add_column :memberships, :role_id, :integer
  end
end
