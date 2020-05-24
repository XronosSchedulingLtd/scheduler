class CreatePreRequisites < ActiveRecord::Migration[4.2]
  def change
    create_table :pre_requisites do |t|
      t.string :label
      t.text :description
      t.integer :element_id
      t.integer :priority

      t.timestamps
    end
  end
end
