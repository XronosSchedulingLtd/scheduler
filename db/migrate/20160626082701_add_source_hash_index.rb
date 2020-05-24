class AddSourceHashIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :events, :source_hash
  end
end
