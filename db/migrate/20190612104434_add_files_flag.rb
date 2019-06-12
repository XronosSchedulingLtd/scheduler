class AddFilesFlag < ActiveRecord::Migration
  def change
    add_column :users, :can_has_files, :boolean, default: false
  end
end
