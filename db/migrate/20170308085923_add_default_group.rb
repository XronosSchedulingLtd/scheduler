class AddDefaultGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :exam_cycles, :default_group_element_id, :integer, :default => nil
    add_column :exam_cycles, :default_quantity, :integer, :default => 5
  end
end
