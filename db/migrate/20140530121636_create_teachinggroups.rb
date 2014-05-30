class CreateTeachinggroups < ActiveRecord::Migration
  def change
    create_table :teachinggroups do |t|
      t.string :name
      t.integer :era_id
      t.boolean :current
      t.integer :source_id

      t.timestamps
    end

    add_index :teachinggroups, :era_id
    add_index :teachinggroups, :source_id
  end
end
