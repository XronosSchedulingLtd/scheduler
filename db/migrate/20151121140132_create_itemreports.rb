class CreateItemreports < ActiveRecord::Migration
  def change
    create_table :itemreports do |t|
      t.integer :concern_id
      t.boolean :compact,          :default => false
      t.boolean :duration,         :default => false
      t.boolean :mark_end,         :default => false
      t.boolean :locations,        :default => false
      t.boolean :staff,            :default => false
      t.boolean :pupils,           :default => false
      t.boolean :periods,          :default => false
      t.date    :starts_on
      t.date    :ends_on
      t.boolean :twelve_hour,      :default => false
      t.boolean :end_time,         :default => true
      t.boolean :breaks,           :default => false
      t.boolean :suppress_empties, :default => false
      t.boolean :tentative,        :default => false
      t.boolean :firm,             :default => false
      t.string  :categories,       :default => ""
      t.integer :excluded_element_id
      t.timestamps
    end
    add_index :itemreports, :concern_id
  end
end
