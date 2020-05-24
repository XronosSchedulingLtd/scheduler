class AddCanBorrowFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :can_borrow, :boolean, :default => false
  end
end
