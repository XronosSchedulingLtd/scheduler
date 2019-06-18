class CreateUserFiles < ActiveRecord::Migration
  def change
    create_table :user_files do |t|
      t.integer :owner_id
      t.string  :original_file_name
      t.string  :nanoid
      t.integer :file_size, default: 0
      t.timestamps null: false
    end
    add_index :user_files, :nanoid, unique: true

    add_column :settings, :user_files_dir, :string, default: "UserFiles"
    add_column :settings, :user_file_allowance, :integer, default: 0
  end
end
