class EraShortNames < ActiveRecord::Migration
  def change
    add_column :eras, :short_name, :string, :default => ""
  end
end
