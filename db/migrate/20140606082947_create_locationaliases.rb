class CreateLocationaliases < ActiveRecord::Migration[4.2]
  def change
    create_table :locationaliases do |t|
      t.string :name
      t.integer :source_id
      t.integer :location_id

      t.timestamps
    end

    remove_column :locations, :source_id

  end
end
