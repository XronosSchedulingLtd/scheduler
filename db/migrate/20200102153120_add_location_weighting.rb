class AddLocationWeighting < ActiveRecord::Migration
  def change
    add_column :locations, :weighting, :integer, default: 100
  end
end
