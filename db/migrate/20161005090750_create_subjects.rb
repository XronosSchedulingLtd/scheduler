class CreateSubjects < ActiveRecord::Migration
  def change
    create_table :subjects do |t|
      t.string  :name
      t.boolean :current, default: true
      t.integer :datasource_id
      t.integer :source_id

      t.timestamps
    end

    add_column :teachinggrouppersonae, :subject_id, :integer
    add_index  :teachinggrouppersonae, :subject_id

    add_column :teachinggrouppersonae, :yeargroup,  :integer

    create_table :staffs_teachinggrouppersonae, id: false do |t|
      t.belongs_to :staff,                index: true
      t.belongs_to :teachinggrouppersona, index: true
    end

    create_table :staffs_subjects, id: false do |t|
      t.belongs_to :staff,   index: true
      t.belongs_to :subject, index: true
    end
  end
end
