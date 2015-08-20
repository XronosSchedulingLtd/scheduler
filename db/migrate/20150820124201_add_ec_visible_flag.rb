class AddEcVisibleFlag < ActiveRecord::Migration
  def change
    add_column :eventcategories, :visible, :boolean, :default => true
  end
end
