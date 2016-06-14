class CreateDatasources < ActiveRecord::Migration
  def change
    create_table :datasources do |t|
      t.string :name

      t.timestamps
    end
  end
end
