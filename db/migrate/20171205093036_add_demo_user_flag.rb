class AddDemoUserFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :demo_user, :boolean, default: false
  end
end
