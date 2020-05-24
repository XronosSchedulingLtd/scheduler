class CreateRotaSlots < ActiveRecord::Migration[4.2]
  def change
    create_table :rota_slots do |t|
      t.integer :rota_template_id
      t.time :starts_at
      t.time :ends_at
      t.text :days

      t.timestamps
    end
  end
end
