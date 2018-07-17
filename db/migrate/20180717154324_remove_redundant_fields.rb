class RemoveRedundantFields < ActiveRecord::Migration
  def change
    remove_column :memberships, :as_at
    remove_column :memberships, :role_id
  end
end
