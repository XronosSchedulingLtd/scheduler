class AddPropertiesAndServices < ActiveRecord::Migration[4.2]
  def change
    create_table :properties do |t|
      t.string :name
      t.timestamps
    end
    create_table :services do |t|
      t.string :name
      t.timestamps
    end
  end
end
