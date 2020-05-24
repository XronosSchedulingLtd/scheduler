class AddPublicGroupFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :users,  :public_groups, :boolean, :default => false
    add_column :groups, :make_public,   :boolean, :default => false
  end
end
