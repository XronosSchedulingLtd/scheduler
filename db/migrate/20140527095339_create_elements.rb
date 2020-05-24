class CreateElements < ActiveRecord::Migration[4.2]
  def change
    create_table :elements do |t|
      t.string :name
      t.integer :entity_id
      t.string :entity_type

      t.timestamps
    end

    add_index :elements, :entity_id

  end
end
