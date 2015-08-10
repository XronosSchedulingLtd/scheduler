class AddPreferredColour < ActiveRecord::Migration
  def change
    add_column :elements, :preferred_colour, :string
  end
end
