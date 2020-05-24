class AddWrappingSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :wrapping_before_mins,      :integer, default: 60
    add_column :settings, :wrapping_after_mins,       :integer, default: 30
    add_column :settings, :wrapping_eventcategory_id, :integer
  end
end
