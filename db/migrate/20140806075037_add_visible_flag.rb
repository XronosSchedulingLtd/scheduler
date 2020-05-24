class AddVisibleFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :interests, :visible, :boolean, :default => true
  end
end
