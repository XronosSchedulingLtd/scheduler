class AddPrerequisiteFlag < ActiveRecord::Migration
  def change
    add_column :users, :show_pre_requisites, :boolean, :default => true
  end
end
