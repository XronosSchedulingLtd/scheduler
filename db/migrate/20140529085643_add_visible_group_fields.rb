class AddVisibleGroupFields < ActiveRecord::Migration
  def change
    add_column :groups, :visible_group_id,   :integer
    add_column :groups, :visible_group_type, :string
  end
end
