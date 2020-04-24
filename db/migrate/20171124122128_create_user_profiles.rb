class CreateUserProfiles < ActiveRecord::Migration[4.2]
  def change
    create_table :user_profiles do |t|
      t.string :name
      t.text   :permissions

      t.timestamps
    end

    add_column :users, :user_profile_id, :integer
    add_column :users, :permissions,     :text

    reversible do |change|
      change.up do
        User.link_to_profiles
      end
    end
  end
end
