class CreateStaffs < ActiveRecord::Migration[4.2]
  def change
    create_table :staffs do |t|
      t.string :name
      t.string :initials
      t.string :surname
      t.string :title
      t.string :forename
      t.string :email
      t.integer :source_id
      t.boolean :active

      t.timestamps
    end
    add_index :staffs, :source_id
  end
end
