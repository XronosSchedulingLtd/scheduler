class AddViewFormsFlag < ActiveRecord::Migration
  def change
    add_column :users, :can_view_forms, :boolean, default: false
  end
end
