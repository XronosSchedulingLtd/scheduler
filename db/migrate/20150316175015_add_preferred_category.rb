class AddPreferredCategory < ActiveRecord::Migration
  def change
    add_column :users, :preferred_event_category_id, :integer, :default => nil
  end
end
