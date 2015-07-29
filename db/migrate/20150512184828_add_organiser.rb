class AddOrganiser < ActiveRecord::Migration
  def change
    add_column :events, :organiser_id, :integer, :default => nil
  end
end
