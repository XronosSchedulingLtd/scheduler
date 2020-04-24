class CreateOwnerships < ActiveRecord::Migration[4.2]
  def change
    create_table :ownerships do |t|
      t.integer :user_id
      t.integer :element_id

      t.timestamps
    end
  end
end
