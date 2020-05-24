class AddOrganiser < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :organiser_id, :integer, :default => nil
  end
end
