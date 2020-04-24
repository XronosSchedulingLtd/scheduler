class AddViewFormsFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_view_forms, :boolean, default: false
  end
end
