class AddClashesFlag < ActiveRecord::Migration
  def change
    add_column :events, :has_clashes, :boolean, :default => false
    add_index :events, :has_clashes
  end

end
