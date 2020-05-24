class Addenddot < ActiveRecord::Migration[4.2]
  def change
    add_column :itemreports, :enddot, :boolean, :default => true
  end
end
