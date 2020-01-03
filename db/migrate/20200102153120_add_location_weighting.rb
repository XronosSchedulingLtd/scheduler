class AddLocationWeighting < ActiveRecord::Migration
  def change
    add_column :locations, :weighting, :integer, default: 100
    add_column :locations, :subsidiary_to_id, :integer
  end
end
