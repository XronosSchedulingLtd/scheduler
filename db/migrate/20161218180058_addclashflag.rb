class Addclashflag < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :clashcheck, :boolean, default: false
  end
end
