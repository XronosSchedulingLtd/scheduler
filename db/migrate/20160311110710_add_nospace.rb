class AddNospace < ActiveRecord::Migration[4.2]
  def change
    add_column :itemreports, :no_space, :boolean, :default => false
  end
end
