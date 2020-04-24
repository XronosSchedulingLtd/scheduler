class AddNamesEventFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :commitments, :names_event, :boolean, :default => false
  end
end
