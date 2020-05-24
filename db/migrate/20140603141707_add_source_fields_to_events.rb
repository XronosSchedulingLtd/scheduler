class AddSourceFieldsToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :compound,    :boolean, :default => false
    add_column :events, :source_id,   :integer, :default => 0
    add_column :events, :source_hash, :string
  end
end
