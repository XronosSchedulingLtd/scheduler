class AddTeachesFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :staffs, :teaches, :boolean
  end
end
