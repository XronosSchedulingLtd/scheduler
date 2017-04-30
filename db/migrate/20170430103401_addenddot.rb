class Addenddot < ActiveRecord::Migration
  def change
    add_column :itemreports, :enddot, :boolean, :default => true
  end
end
