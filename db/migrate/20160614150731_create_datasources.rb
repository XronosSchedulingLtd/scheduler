class CreateDatasources < ActiveRecord::Migration[4.2]
  def change
    create_table :datasources do |t|
      t.string :name

      t.timestamps
    end
  end
end
