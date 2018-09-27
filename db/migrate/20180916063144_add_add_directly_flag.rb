class AddAddDirectlyFlag < ActiveRecord::Migration
  def change
    add_column :elements, :add_directly, :boolean, default: true
    add_column :services, :add_directly, :boolean, default: true
  end
end
