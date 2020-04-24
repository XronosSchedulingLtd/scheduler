class AddSourceIdToCommitments < ActiveRecord::Migration[4.2]
  def change
    add_column :commitments, :source_id, :integer, :default => nil
  end
end
