class CreateConcernSets < ActiveRecord::Migration[4.2]
  def change
    create_table :concern_sets do |t|
      t.string :name
      t.integer :owner_id

      t.timestamps null: false
    end
    add_column :concerns, :concern_set_id,         :integer, default: nil
    add_column :users,    :current_concern_set_id, :integer, default: nil
  end
end
