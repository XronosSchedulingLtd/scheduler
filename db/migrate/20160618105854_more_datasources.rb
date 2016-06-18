class MoreDatasources < ActiveRecord::Migration
  def change
    add_column :locationaliases, :datasource_id, :integer
  end
end
