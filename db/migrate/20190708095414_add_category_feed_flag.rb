class AddCategoryFeedFlag < ActiveRecord::Migration
  def change
    add_column :properties, :feed_as_category, :boolean, default: false
  end
end
