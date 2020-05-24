class AddEventFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :flagcolour, :string, :default => nil
  end
end
