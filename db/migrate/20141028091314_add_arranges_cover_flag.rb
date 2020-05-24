class AddArrangesCoverFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :arranges_cover, :boolean, :default => false
  end
end
