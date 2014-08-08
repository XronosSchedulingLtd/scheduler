class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.integer :current_era_id

      t.timestamps
    end
  end
end
