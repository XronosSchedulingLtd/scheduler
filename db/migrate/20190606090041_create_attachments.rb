class CreateAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :attachments do |t|
      t.integer :parent_id
      t.string :parent_type
      t.integer :user_file_id

      t.timestamps null: false
    end
    add_index :attachments, :user_file_id
    add_index :attachments, [:parent_id, :parent_type]
  end
end
