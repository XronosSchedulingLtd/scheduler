class MoreDatasources < ActiveRecord::Migration[4.2]
  def change
    add_column :locationaliases, :datasource_id, :integer
  end
end
