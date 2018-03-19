class AddEventCollections < ActiveRecord::Migration
  def change
    create_table :event_collections do |t|
      t.integer :era_id
      t.date    :repetition_start_date
      t.date    :repetition_end_date
      t.text    :days_of_week, default: nil
      t.string  :weeks, default: "AB"
      t.integer :when_in_month, default: 0

      t.timestamps
    end

    add_column :events, :event_collection_id, :integer, default: nil
  end
end
