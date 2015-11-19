class AddUserFlags < ActiveRecord::Migration
  def change
    add_column :users, :can_has_groups,   :boolean, :default => false
    add_column :users, :can_find_free,    :boolean, :default => false
    add_column :users, :can_add_concerns, :boolean, :default => false
    add_column :users, :can_su,           :boolean, :default => false
    remove_column :users, :show_calendar
  end
end
