class CreateExamCycles < ActiveRecord::Migration[4.2]
  def change
    create_table :exam_cycles do |t|
      t.string :name
      t.integer :default_rota_template_id
      t.date :starts_on
      t.date :ends_on

      t.timestamps
    end
  end
end
