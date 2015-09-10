class AddDefaultEventText < ActiveRecord::Migration
  def change
    add_column :users, :default_event_text, :string, :default => ""
  end
end
