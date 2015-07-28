class AddPerpetualEra < ActiveRecord::Migration
  def change
    add_column :settings, :perpetual_era_id, :integer
  end
end
