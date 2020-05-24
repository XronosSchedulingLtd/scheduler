class AddNeedPeopleFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :resourcegrouppersonae, :needs_people, :boolean, default: false
  end
end
