class AddProtoCommitmentLink < ActiveRecord::Migration
  def change
    add_column :commitments, :proto_commitment_id, :integer, :default => nil
    add_index :commitments, :proto_commitment_id
  end
end
