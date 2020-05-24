class AddViewUnconfirmedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_view_unconfirmed, :boolean, default: false
  end
end
