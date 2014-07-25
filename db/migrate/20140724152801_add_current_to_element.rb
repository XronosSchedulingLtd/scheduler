class AddCurrentToElement < ActiveRecord::Migration
  def change
    add_column :elements, :current, :boolean, :default => false
  end
end
