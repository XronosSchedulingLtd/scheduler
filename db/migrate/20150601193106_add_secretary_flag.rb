class AddSecretaryFlag < ActiveRecord::Migration
  def change
    add_column :users, :secretary, :boolean, :default => false
  end
end
