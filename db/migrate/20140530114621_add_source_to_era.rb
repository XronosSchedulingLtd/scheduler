class AddSourceToEra < ActiveRecord::Migration[4.2]
  def change
    add_column :eras, :source_id, :integer
  end
end
