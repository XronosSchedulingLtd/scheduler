class AddEventSourceIdIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :events, :source_id
  end
end
