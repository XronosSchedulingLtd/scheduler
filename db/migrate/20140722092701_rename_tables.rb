class RenameTables < ActiveRecord::Migration
  def change
    rename_table :teachinggroups, :teachinggrouppersonae
    rename_table :tutorgroups,    :tutorgrouppersonae
    rename_column :groups, :visible_group_id,   :persona_id
    rename_column :groups, :visible_group_type, :persona_type
  end
end
