class AddStartDay < ActiveRecord::Migration
  def change
    add_column :users, :firstday, :integer, :default => 0
  end
end
