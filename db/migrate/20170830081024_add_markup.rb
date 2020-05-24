class AddMarkup < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :event_creation_markup, :text
    add_column :settings, :event_creation_html, :text
  end
end
