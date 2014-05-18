class AddAllDay < ActiveRecord::Migration
  def change
    add_column :events, :all_day, :boolean, :default => false
  end
end
