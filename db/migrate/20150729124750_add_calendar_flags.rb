class AddCalendarFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :concerns,        :auto_add,   :boolean, :default => false
    add_column :eventcategories, :deprecated, :boolean, :default => false
  end
end
