class AddClashFlags < ActiveRecord::Migration
  def change
    add_column :users, :clash_weekly,    :boolean, :default => false
    add_column :users, :clash_daily,     :boolean, :default => false
    add_column :users, :clash_immediate, :boolean, :default => false
  end
end
