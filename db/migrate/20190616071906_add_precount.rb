class AddPrecount < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :commitments_count, :integer, null: false, default: 0
    reversible do |change|
      change.up do
        Request.set_initial_counts
      end
    end
  end
end
