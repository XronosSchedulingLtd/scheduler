class CreateSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :settings do |t|
      t.integer :current_era_id

      t.timestamps
    end
  end
end
