class AddEventCollections < ActiveRecord::Migration
  def change
    create_table :event_collections do |t|
      t.integer :era_id
      t.date    :repetition_start_date
      t.date    :repetition_end_date
      t.string  :days_of_week, default: nil
      t.string  :weeks, default: nil
      t.integer :when_in_month, default: 0

      t.timestamps
    end

    add_column :events, :event_collection_id, :integer, default: nil
  end
end
