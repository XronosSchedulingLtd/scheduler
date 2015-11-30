class AddNotesAndFiles < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string  :title,    :default => ""
      t.text    :contents
      t.integer :parent_id
      t.string  :parent_type
      t.integer :owner_id
      t.integer :visibility, :default => 0
      t.integer :note_type,  :default => 0

      t.timestamps
    end
    add_index :notes, :parent_id
    add_index :notes, :owner_id

    create_table :attachments do |t|
      t.integer :note_id
      t.string  :original_file_name
      t.string  :saved_as

      t.timestamps
    end
    add_index :attachments, :note_id
  end
end
