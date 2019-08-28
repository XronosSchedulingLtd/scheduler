class AddEmailPersistenceField < ActiveRecord::Migration
  def change
    add_column :settings, :email_keep_days, :integer, default: 0
    add_column :settings, :event_keep_years, :integer, default: 0
  end
end
