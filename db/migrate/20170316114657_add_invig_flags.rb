class AddInvigFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :invig_weekly,        :boolean, :default => true
    add_column :users, :invig_daily,         :boolean, :default => true
    add_column :users, :last_invig_run_date, :date,    :default => nil
  end
end
