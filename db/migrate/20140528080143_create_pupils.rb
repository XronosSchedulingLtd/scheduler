class CreatePupils < ActiveRecord::Migration
  def change
    create_table :pupils do |t|
      t.string :name
      t.string :surname
      t.string :forename
      t.string :known_as
      t.string :email
      t.string :candidate_no
      t.integer :start_year
      t.integer :source_id

      t.timestamps
    end
    add_index :pupils, :source_id
  end
end
