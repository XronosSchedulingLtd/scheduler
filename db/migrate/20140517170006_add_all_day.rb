class AddAllDay < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :all_day, :boolean, :default => false
  end
end
