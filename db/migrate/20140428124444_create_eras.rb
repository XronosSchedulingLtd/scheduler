class CreateEras < ActiveRecord::Migration[4.2]
  def change
    create_table :eras do |t|
      t.string :name
      t.date :starts_on
      t.date :ends_on

      t.timestamps
    end
  end
end
