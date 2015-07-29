class AddOrganiserIndex < ActiveRecord::Migration
  def change
    add_index :events, :organiser_id
    add_column :events, :organiser_ref, :text
    add_column :users, :show_calendar, :boolean, :default => false
    add_column :users, :show_owned, :boolean, :default => true
  end
end
