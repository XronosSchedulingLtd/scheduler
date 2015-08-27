class AddLocationIdIndex < ActiveRecord::Migration
  def change
    add_index :locationaliases, :location_id
  end
end
