class AddResourceClashFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :resource_clash_notification, :boolean, default: false
  end
end
