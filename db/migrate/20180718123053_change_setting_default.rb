class ChangeSettingDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default :settings, :prep_suffix, "(P)"
  end
end
