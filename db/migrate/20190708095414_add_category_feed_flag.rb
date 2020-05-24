class AddCategoryFeedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :properties, :feed_as_category, :boolean, default: false
  end
end
