class AddAuthType < ActiveRecord::Migration
  def change
    add_column :settings, :auth_type, :integer, :default => 0
  end
end
