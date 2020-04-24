class AddUserColours < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :colour_involved,     :string, :default => "#234B58"
    add_column :users, :colour_not_involved, :string, :default => "#254117"
  end
end
