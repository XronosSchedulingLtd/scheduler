class AddPreferredCategory < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :preferred_event_category_id, :integer, :default => nil
  end
end
