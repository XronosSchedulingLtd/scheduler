class Addnoresourceflag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :warn_no_resources, :boolean, default: true
  end
end
