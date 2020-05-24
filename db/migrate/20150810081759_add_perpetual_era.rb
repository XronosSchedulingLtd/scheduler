class AddPerpetualEra < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :perpetual_era_id, :integer
  end
end
