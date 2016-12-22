class AddMulticover < ActiveRecord::Migration
  def change
    add_column :staffs, :multicover, :boolean, :default => false
  end
end
