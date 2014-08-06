class AddVisibleFlag < ActiveRecord::Migration
  def change
    add_column :interests, :visible, :boolean, :default => true
  end
end
