class AddSecretaryFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :secretary, :boolean, :default => false
  end
end
