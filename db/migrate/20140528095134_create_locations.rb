class CreateLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :locations do |t|
      t.string :short_name
      t.string :name
      t.integer :source_id
      t.boolean :active

      t.timestamps
    end
    add_index :locations, :source_id
  end
end
