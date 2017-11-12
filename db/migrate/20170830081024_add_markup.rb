class AddMarkup < ActiveRecord::Migration
  def change
    add_column :settings, :event_creation_markup, :text
    add_column :settings, :event_creation_html, :text
  end
end
