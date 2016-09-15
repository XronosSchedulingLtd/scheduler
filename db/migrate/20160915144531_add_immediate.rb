class AddImmediate < ActiveRecord::Migration
  def change
    add_column :users, :immediate_notification, :boolean, :default => false
  end
end
