class AddDoesCoverFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :staffs, :does_cover, :boolean
  end
end
