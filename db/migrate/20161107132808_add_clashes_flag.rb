class AddClashesFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :has_clashes, :boolean, :default => false
    add_index :events, :has_clashes
  end

end
