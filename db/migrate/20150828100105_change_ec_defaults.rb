class ChangeEcDefaults < ActiveRecord::Migration
  def change
    change_column_default :eventcategories, :pecking_order, 20
  end
end
