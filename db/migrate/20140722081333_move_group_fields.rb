class MoveGroupFields < ActiveRecord::Migration
  def change
    add_column :groups, :name,    :string
    add_column :groups, :era_id,  :integer
    add_column :groups, :current, :boolean, :default => false
    add_index  :groups, :era_id
  end
end
