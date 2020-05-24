class AddMergeableFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :can_merge, :boolean, :default => false
  end
end
