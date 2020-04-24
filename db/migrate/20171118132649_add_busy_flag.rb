class AddBusyFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :busy, :boolean, default: true
  end
end
