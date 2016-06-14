class AddDatasourceId < ActiveRecord::Migration
  def change
    add_column :staffs, :datasource_id, :integer
    add_index :staffs, :datasource_id
    add_column :pupils, :datasource_id, :integer
    add_index :pupils, :datasource_id
  end
end
