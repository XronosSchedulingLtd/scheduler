class AddUuid < ActiveRecord::Migration
  def change
    add_column :elements, :uuid, :string
    add_index :elements, :uuid, unique: true
  end
end
