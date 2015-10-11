class CreateFreefinders < ActiveRecord::Migration
  def change
    create_table :freefinders do |t|
      t.integer :element_id
      t.string :name
      t.integer :owner_id
      t.date :on
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
    add_index :freefinders, :owner_id
  end
end
