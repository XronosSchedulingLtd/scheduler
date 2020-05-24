class CreateConcerns < ActiveRecord::Migration[4.2]
  def change
    create_table :concerns do |t|
      t.integer :user_id
      t.integer :element_id
      t.boolean :equality, :default => false, :null => false
      t.boolean :owns,     :default => false, :null => false
      t.boolean :visible,  :default => true,  :null => false
      t.string  :colour, :null => false

      t.timestamps
    end
    add_index :concerns, :user_id
    add_index :concerns, :element_id
  end
end
