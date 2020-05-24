class AddEqualsFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :ownerships, :equality, :boolean, :default => false
  end
end
