class AddEqualsFlag < ActiveRecord::Migration
  def change
    add_column :ownerships, :equality, :boolean, :default => false
  end
end
