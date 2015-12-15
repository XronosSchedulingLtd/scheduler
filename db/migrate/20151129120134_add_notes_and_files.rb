class AddNotesAndFiles < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string  :title,    :default => ""
      t.text    :contents
      t.integer :parent_id
      t.string  :parent_type
      t.integer :owner_id
      t.integer :promptnote_id
      t.boolean :visible_guest, :default => false
      t.boolean :visible_staff, :default => true
      t.boolean :visible_pupil, :default => false
      t.integer :note_type,  :default => 0

      t.timestamps
    end
    add_index :notes, :parent_id
    add_index :notes, :owner_id

    create_table :attachments do |t|
      t.string  :description
      t.integer :parent_id
      t.string  :parent_type
      t.string  :original_file_name
      t.string  :meta_data
      t.string  :saved_as
      t.boolean :visible_guest, :default => false
      t.boolean :visible_staff, :default => true
      t.boolean :visible_pupil, :default => false

      t.timestamps
    end

    create_table :promptnotes do |t|
      t.string  :title,    :default => ""
      t.text    :prompt
      t.text    :default_contents
      t.integer :element_id
      t.boolean :read_only, :default => false

      t.timestamps
    end
    add_index :promptnotes, :element_id

    add_column :itemreports, :notes, :boolean, :default => false

  end
end
