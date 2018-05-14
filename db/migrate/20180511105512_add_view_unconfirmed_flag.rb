class AddViewUnconfirmedFlag < ActiveRecord::Migration
  def change
    add_column :users, :can_view_unconfirmed, :boolean, default: false
  end
end
