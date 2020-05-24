class CreateRotaTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :rota_templates do |t|
      t.string :name

      t.timestamps
    end
  end
end
