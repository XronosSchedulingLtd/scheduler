class AddTeachesFlag < ActiveRecord::Migration
  def change
    add_column :staffs, :teaches, :boolean
  end
end
