class AddFieldsToResourceGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :resourcegrouppersonae, :loading_report_days, :integer, default: 0
    add_column :resourcegrouppersonae, :wrapping_mins, :integer, default: 0
  end
end
