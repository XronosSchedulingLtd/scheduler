class AddNamesEventFlag < ActiveRecord::Migration
  def change
    add_column :commitments, :names_event, :boolean, :default => false
  end
end
