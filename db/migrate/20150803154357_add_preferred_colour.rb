class AddPreferredColour < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :preferred_colour, :string
  end
end
