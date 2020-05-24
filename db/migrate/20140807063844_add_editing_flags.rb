class AddEditingFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :owner_id, :integer, :default => nil
    add_column :users,    :editor,   :boolean, :default => false

    add_index :elements, :owner_id
    add_index :events,   :owner_id
  end
end
