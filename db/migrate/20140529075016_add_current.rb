class AddCurrent < ActiveRecord::Migration
  def change
    add_column :locations, :current, :boolean, :default => false
    add_column :pupils,    :current, :boolean, :default => false
    add_column :staffs,    :current, :boolean, :default => false
  end
end
