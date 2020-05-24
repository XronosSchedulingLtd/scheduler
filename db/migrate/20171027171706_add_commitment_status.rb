class AddCommitmentStatus < ActiveRecord::Migration[4.2]
  def change
    add_column    :commitments, :status,       :integer, default: 0
    rename_column :commitments, :rejected,     :was_rejected
    rename_column :commitments, :constraining, :was_constraining
    add_index     :commitments, :status
    reversible do |change|
      change.up do
        Commitment.populate_statuses
      end
    end
  end
end
