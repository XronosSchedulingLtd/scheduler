class AddPermissionFlags < ActiveRecord::Migration
  def change
    add_column :users, :can_add_resources, :boolean, default: false
    add_column :users, :can_add_notes,     :boolean, default: false
    reversible do |change|
      change.up do
        User.populate_resource_and_note_flags
      end
    end
  end

end
