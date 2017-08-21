class AddJournals < ActiveRecord::Migration
  def change
    create_table :journals do |t|
      t.integer   :event_id
      t.text      :event_body
      t.integer   :event_eventcategory_id
      t.integer   :event_owner_id
      t.datetime  :event_starts_at
      t.datetime  :event_ends_at
      t.boolean   :event_all_day
      t.integer   :event_organiser_id
      t.text      :event_organiser_ref

      t.timestamps
    end
    add_index :journals, :event_id

    create_table :journal_entries do |t|
      t.integer    :journal_id
      t.integer    :user_id
      t.integer    :entry_type
      t.text       :details

      t.timestamps
    end
    add_index :journal_entries, :journal_id
  end
end
