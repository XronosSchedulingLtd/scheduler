class AddMulticover < ActiveRecord::Migration[4.2]
  def change
    add_column :staffs, :multicover, :boolean, :default => false
  end
end
