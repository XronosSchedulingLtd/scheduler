class CommitmentRequestLink < ActiveRecord::Migration[4.2]
  def change
    add_column :commitments, :request_id, :integer, :default => nil
    add_index :commitments, :request_id
  end
end
