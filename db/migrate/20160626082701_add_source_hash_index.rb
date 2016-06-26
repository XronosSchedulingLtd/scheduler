class AddSourceHashIndex < ActiveRecord::Migration
  def change
    add_index :events, :source_hash
  end
end
