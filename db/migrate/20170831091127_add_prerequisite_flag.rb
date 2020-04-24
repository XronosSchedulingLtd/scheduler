class AddPrerequisiteFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :show_pre_requisites, :boolean, :default => true
  end
end
