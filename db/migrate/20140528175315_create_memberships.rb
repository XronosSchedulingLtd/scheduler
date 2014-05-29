class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.integer :group_id,   :null => false
      t.integer :element_id, :null => false
      t.date    :starts_on,  :null => false
      t.date    :ends_on
      t.date    :as_at
      t.boolean :inverse,    :null => false

      t.timestamps
    end
    add_index :memberships, :group_id
    add_index :memberships, :element_id
  end
end
