class AddEventFlag < ActiveRecord::Migration
  def change
    add_column :events, :flagcolour, :string, :default => nil
  end
end
