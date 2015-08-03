class AddControlFlag < ActiveRecord::Migration
  def change
    add_column :concerns, :controls, :boolean, :default => false
  end
end
