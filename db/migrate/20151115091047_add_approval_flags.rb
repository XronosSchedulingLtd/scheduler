class AddApprovalFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :users,    :email_notification, :boolean, :default => true
    add_column :concerns, :skip_permissions,   :boolean, :default => false
  end
end
