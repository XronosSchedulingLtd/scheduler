class AddApiFields < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :uuid, :string
    add_index  :users, :uuid, unique: true
    add_column :users, :can_api, :boolean, default: false
    reversible do |change|
      change.up do
        User.generate_uuids
      end
    end
  end
end
