class AddCompactable < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :compactable, :boolean, :default => true
  end
end
