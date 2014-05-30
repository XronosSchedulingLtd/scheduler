class AddSourceToEra < ActiveRecord::Migration
  def change
    add_column :eras, :source_id, :integer
  end
end
