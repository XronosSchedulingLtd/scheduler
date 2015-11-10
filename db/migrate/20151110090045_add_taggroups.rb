class AddTaggroups < ActiveRecord::Migration
  def change
    create_table :taggrouppersonae do |t|
      t.integer :source_id
      t.timestamps
    end

    add_index :taggrouppersonae, :source_id
  end
end
