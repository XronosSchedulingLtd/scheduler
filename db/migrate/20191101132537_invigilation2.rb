class Invigilation2 < ActiveRecord::Migration
  def change
    add_column :locations,   :num_invigilators,    :integer, default: 1
    add_column :exam_cycles, :selector_element_id, :integer, default: nil
  end
end
