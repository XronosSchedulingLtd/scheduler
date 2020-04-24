class AddLocationIdIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :locationaliases, :location_id
  end
end
