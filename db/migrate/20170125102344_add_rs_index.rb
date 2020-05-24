class AddRsIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :rota_slots, :rota_template_id
  end
end
