class AddColours < ActiveRecord::Migration[4.2]
  def change
    add_column :ownerships, :colour, :string, :default => "#225599"
    add_column :interests,  :colour, :string, :default => "gray"
  end
end
