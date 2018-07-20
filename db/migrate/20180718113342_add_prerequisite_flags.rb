class AddPrerequisiteFlags < ActiveRecord::Migration
  def change
    add_column :pre_requisites, :pre_creation,      :boolean, default: true
    add_column :pre_requisites, :quick_button,      :boolean, default: true
    add_column :settings,       :max_quick_buttons, :integer, default: 0
  end
end
