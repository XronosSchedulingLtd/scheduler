class AddEditorFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :edit_all_events, :boolean, :default => false
    add_column :users, :subedit_all_events, :boolean, :default => false
  end
end
