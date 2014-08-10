class AddDoesCoverFlag < ActiveRecord::Migration
  def change
    add_column :staffs, :does_cover, :boolean
  end
end
