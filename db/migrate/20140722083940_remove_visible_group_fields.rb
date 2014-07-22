class RemoveVisibleGroupFields < ActiveRecord::Migration
  def change
    remove_column :tutorgroups, :name
    remove_column :tutorgroups, :era_id
    remove_column :tutorgroups, :current
    remove_index  :teachinggroups, :era_id
    remove_column :teachinggroups, :name
    remove_column :teachinggroups, :era_id
    remove_column :teachinggroups, :current
  end
end
