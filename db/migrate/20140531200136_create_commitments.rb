class CreateCommitments < ActiveRecord::Migration
  def change
    create_table :commitments do |t|
      t.integer :event_id
      t.integer :element_id
      t.integer :covering_id
    end

    add_index :commitments, :event_id
    add_index :commitments, :element_id
    add_index :commitments, :covering_id
  end
end
