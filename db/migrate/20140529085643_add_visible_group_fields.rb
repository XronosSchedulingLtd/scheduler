class AddVisibleGroupFields < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :visible_group_id,   :integer
    add_column :groups, :visible_group_type, :string
  end
end
