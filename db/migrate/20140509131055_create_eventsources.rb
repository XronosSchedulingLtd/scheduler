class CreateEventsources < ActiveRecord::Migration[4.2]
  def change
    create_table :eventsources do |t|
      t.string :name

      t.timestamps
    end
  end
end
