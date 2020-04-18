class AddLocationWeighting < ActiveRecord::Migration[4.2]
  def change
    add_column :locations, :weighting, :integer, default: 100
    add_column :locations, :subsidiary_to_id, :integer
  end
end
