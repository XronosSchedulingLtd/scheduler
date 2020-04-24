class AddCurrentFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :properties, :current, :boolean, default: true
    add_column :services,   :current, :boolean, default: true
  end
end
