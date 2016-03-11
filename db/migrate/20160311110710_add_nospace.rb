class AddNospace < ActiveRecord::Migration
  def change
    add_column :itemreports, :no_space, :boolean, :default => false
  end
end
