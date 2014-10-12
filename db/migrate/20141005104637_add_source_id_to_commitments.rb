class AddSourceIdToCommitments < ActiveRecord::Migration
  def change
    add_column :commitments, :source_id, :integer, :default => nil
  end
end
