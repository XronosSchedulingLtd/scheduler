class AddSourceIdToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :source_id,     :integer
    add_column :groups, :source_id_str, :string
    add_column :groups, :datasource_id, :integer
    add_index :groups, :source_id
    add_index :groups, :source_id_str
    add_index :groups, :datasource_id
  end
end
