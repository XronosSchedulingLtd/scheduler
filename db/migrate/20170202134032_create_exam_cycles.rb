class CreateExamCycles < ActiveRecord::Migration
  def change
    create_table :exam_cycles do |t|
      t.string :name
      t.integer :default_rota_template_id

      t.timestamps
    end
  end
end
