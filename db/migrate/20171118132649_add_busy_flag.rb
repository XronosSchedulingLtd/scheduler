class AddBusyFlag < ActiveRecord::Migration
  def change
    add_column :eventcategories, :busy, :boolean, default: true
  end
end
