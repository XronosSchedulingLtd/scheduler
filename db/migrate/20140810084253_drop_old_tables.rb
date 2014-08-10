class DropOldTables < ActiveRecord::Migration
  def change
    drop_table :teachinggroups
    drop_table :tutorgroups
  end
end
