class AddNeedPeopleFlag < ActiveRecord::Migration
  def change
    add_column :resourcegrouppersonae, :needs_people, :boolean, default: false
  end
end
