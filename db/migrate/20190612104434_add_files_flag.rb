class AddFilesFlag < ActiveRecord::Migration
  def change
    add_column :users, :can_has_files, :boolean, default: false
    add_column :users, :loading_notification, :boolean, default: true
  end
end