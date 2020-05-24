class AddImmediate < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :immediate_notification, :boolean, :default => false
  end
end
