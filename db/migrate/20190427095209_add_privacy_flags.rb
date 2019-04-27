class AddPrivacyFlags < ActiveRecord::Migration
  def change
    add_column :elements,        :viewable,     :boolean, default: true
    add_column :eventcategories, :confidential, :boolean, default: false
    add_column :events,          :confidential, :boolean, default: false
  end
end
