class CreateEventsources < ActiveRecord::Migration
  def change
    create_table :eventsources do |t|
      t.string :name

      t.timestamps
    end
  end
end
