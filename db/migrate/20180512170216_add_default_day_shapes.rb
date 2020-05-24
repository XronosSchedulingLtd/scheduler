class AddDefaultDayShapes < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :default_display_day_shape_id,     :integer, default: nil
    add_column :settings, :default_free_finder_day_shape_id, :integer, default: nil
  end
end
