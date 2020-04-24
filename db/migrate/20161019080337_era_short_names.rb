class EraShortNames < ActiveRecord::Migration[4.2]
  def change
    add_column :eras, :short_name, :string, :default => ""
  end
end
