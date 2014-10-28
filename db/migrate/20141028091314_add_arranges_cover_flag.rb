class AddArrangesCoverFlag < ActiveRecord::Migration
  def change
    add_column :users, :arranges_cover, :boolean, :default => false
  end
end
