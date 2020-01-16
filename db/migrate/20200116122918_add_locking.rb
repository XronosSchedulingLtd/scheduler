class AddLocking < ActiveRecord::Migration
  def change
    add_column :properties, :locking, :boolean, default: false
    add_column :events, :locked, :boolean, default: false
  end
end
