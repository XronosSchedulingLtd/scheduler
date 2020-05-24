class AddAuthType < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :auth_type, :integer, :default => 0
  end
end
