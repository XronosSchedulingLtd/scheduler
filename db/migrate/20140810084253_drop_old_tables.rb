class DropOldTables < ActiveRecord::Migration[4.2]
  def change
    drop_table :teachinggroups
    drop_table :tutorgroups
  end
end
