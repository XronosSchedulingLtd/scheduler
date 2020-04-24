class AddNextEra < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :next_era_id, :integer, :default => nil
    add_column :settings, :previous_era_id, :integer, :default => nil
  end
end
