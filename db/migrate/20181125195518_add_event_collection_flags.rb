class AddEventCollectionFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :event_collections, :preserve_earlier,    :boolean, default: false
    add_column :event_collections, :preserve_later,      :boolean, default: false
    add_column :event_collections, :preserve_historical, :boolean, default: true
  end
end
