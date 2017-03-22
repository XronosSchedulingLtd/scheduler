class CommitmentRequestLink < ActiveRecord::Migration
  def change
    add_column :commitments, :request_id, :integer, :default => nil
    add_index :commitments, :request_id
  end
end
