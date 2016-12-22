class Addclashflag < ActiveRecord::Migration
  def change
    add_column :eventcategories, :clashcheck, :boolean, default: false
  end
end
