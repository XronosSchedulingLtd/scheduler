class AddEventIndices < ActiveRecord::Migration
  def change
    add_index :events, :starts_at
    add_index :events, :ends_at
    add_index :events, :eventcategory_id
  end
end
