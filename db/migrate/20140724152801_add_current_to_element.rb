class AddCurrentToElement < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :current, :boolean, :default => false
  end
end
