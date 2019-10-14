class AddKnown < ActiveRecord::Migration
  def change
    add_column :users, :known, :boolean, default: false
    add_column :user_profiles, :known, :boolean, default: true
    reversible do |change|
      change.up do
        UserProfile.setup_knowns
      end
    end
  end
end
