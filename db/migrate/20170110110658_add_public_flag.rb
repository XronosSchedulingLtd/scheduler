class AddPublicFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :properties, :make_public, :boolean, :default => false
  end
end
