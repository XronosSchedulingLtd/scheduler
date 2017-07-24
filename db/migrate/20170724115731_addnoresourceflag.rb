class Addnoresourceflag < ActiveRecord::Migration
  def change
    add_column :users, :warn_no_resources, :boolean, default: true
  end
end
