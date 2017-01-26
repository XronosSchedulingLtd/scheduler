class CreateRotaTemplates < ActiveRecord::Migration
  def change
    create_table :rota_templates do |t|
      t.string :name

      t.timestamps
    end
  end
end
