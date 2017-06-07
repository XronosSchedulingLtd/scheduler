class AddRotaTemplateType < ActiveRecord::Migration
  def change
    create_table :rota_template_types do |t|
      t.string :name
      t.timestamps
    end
    add_column :rota_templates, :rota_template_type_id, :integer
    add_column :rota_templates, :owner_id,              :integer
    add_column :rota_templates, :owner_type,            :string
    add_column :users,          :day_shape_id,          :integer
    reversible do |change|
      change.up do
        RotaTemplateType.create_basics
        RotaTemplate.make_all_invigilation
      end
    end
  end
end
