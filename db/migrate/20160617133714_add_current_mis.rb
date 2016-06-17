class AddCurrentMis < ActiveRecord::Migration
  def change
    add_column :settings, :current_mis, :string
    add_column :settings, :previous_mis, :string
  end
end
