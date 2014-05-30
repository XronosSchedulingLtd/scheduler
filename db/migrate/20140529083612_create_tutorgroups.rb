class CreateTutorgroups < ActiveRecord::Migration
  def change
    create_table :tutorgroups do |t|
      t.string :name
      t.string :house
      t.integer :staff_id
      t.integer :era_id
      t.integer :start_year
      t.boolean :current

      t.timestamps
    end
  end
end
