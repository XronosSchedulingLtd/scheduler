class AddMaintenanceProperty < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :maintenance_property_element_id, :integer, default: nil
  end
end
