class CreateInterests < ActiveRecord::Migration[4.2]
  def change
    create_table :interests do |t|
      t.integer :user_id
      t.integer :element_id

      t.timestamps
    end

    add_index :interests, :user_id
    add_index :interests, :element_id
  end
end
