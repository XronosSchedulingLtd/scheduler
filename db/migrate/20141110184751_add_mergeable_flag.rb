class AddMergeableFlag < ActiveRecord::Migration
  def change
    add_column :eventcategories, :can_merge, :boolean, :default => false
  end
end
