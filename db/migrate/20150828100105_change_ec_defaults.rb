class ChangeEcDefaults < ActiveRecord::Migration[4.2]
  def change
    change_column_default :eventcategories, :pecking_order, 20
  end
end
