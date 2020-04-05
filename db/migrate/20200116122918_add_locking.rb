class AddLocking < ActiveRecord::Migration[4.2]
  def change
    add_column :properties, :locking, :boolean, default: false
    add_column :events, :locked, :boolean, default: false
    add_index  :events, :non_existent
    add_column :users, :can_make_shadows, :boolean, default: false
  end
end
