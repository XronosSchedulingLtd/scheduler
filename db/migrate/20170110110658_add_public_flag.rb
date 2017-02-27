class AddPublicFlag < ActiveRecord::Migration
  def change
    add_column :properties, :make_public, :boolean, :default => false
  end
end
