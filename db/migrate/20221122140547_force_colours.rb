class ForceColours < ActiveRecord::Migration[5.2]
  def change
    add_column :elements, :force_colour,      :boolean, default: false
    add_column :elements, :force_weight,      :integer, default: 0
    add_column :events,   :preferred_colours, :text
  end
end
