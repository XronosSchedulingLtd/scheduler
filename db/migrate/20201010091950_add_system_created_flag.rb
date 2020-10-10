class AddSystemCreatedFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :user_files, :system_created, :boolean, default: false
  end
end
