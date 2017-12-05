class AddDemoUserFlag < ActiveRecord::Migration
  def change
    add_column :users, :demo_user, :boolean, default: false
  end
end
