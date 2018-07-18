class ChangeSettingDefault < ActiveRecord::Migration
  def change
    change_column_default :settings, :prep_suffix, "(P)"
  end
end
