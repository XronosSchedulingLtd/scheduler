class AddRsIndex < ActiveRecord::Migration
  def change
    add_index :rota_slots, :rota_template_id
  end
end
