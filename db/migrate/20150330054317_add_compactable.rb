class AddCompactable < ActiveRecord::Migration
  def change
    add_column :eventcategories, :compactable, :boolean, :default => true
  end
end
