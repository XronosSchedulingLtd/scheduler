class AddEcVisibleFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :visible, :boolean, :default => true
  end
end
