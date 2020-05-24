class AddDefaultEventText < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :default_event_text, :string, :default => ""
  end
end
