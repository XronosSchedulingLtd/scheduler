class AddCanBorrowFlag < ActiveRecord::Migration
  def change
    add_column :eventcategories, :can_borrow, :boolean, :default => false
  end
end
