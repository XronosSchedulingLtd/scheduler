class AddCurrentMis < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :current_mis, :string
    add_column :settings, :previous_mis, :string
  end
end
