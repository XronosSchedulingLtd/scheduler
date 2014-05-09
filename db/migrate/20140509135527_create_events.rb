class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.text :body
      t.integer :eventcategory_id, :null => false
      t.integer :eventsource_id,   :null => false
      t.integer :owner_id
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :approximate,      :default => false
      t.boolean :non_existent,     :default => false
      t.boolean :private,          :default => false
      t.integer :reference_id
      t.string :reference_type

      t.timestamps
    end
  end
end
