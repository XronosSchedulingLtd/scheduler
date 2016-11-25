class AddUnnecessaryButtonFlag < ActiveRecord::Migration
  def change
    add_column :users, :unnecessary_buttons, :boolean, :default => true
  end
end
