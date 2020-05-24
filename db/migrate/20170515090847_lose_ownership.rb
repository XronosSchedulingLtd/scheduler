class LoseOwnership < ActiveRecord::Migration[4.2]
  def change
    drop_table :ownerships
  end
end
