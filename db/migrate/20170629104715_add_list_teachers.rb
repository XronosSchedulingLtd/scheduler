class AddListTeachers < ActiveRecord::Migration[4.2]
  def change
    add_column :concerns, :list_teachers, :boolean, default: false
    add_column :users,    :list_teachers, :boolean, default: false
  end
end
