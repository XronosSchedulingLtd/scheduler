class AddFilters < ActiveRecord::Migration
  def change
    #
    #  Using a type of text might seem like overkill, but :string
    #  is limited to 255 chars and I can just conceive of exceeding
    #  that.
    #
    add_column :users, :suppressed_eventcategories, :text
    add_column :users, :extra_eventcategories,      :text
  end
end
