class Addnoresourceflag < ActiveRecord::Migration
  def change
    add_column :users, :no_resource_warning, :boolean, default: true
  end
end
