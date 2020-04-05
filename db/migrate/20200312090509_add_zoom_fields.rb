class AddZoomFields < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :zoom_link_text,     :string
    add_column :settings, :zoom_link_base_url, :string
    add_column :staffs,   :zoom_id,            :string
  end
end
