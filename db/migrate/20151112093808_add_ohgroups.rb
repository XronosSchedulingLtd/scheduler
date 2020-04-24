class AddOhgroups < ActiveRecord::Migration[4.2]
  def change
    create_table :otherhalfgrouppersonae do |t|
      t.integer :source_id
      t.timestamps
    end

    add_index :otherhalfgrouppersonae, :source_id
  end
end
