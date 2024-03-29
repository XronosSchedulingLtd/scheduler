class AddPrivacyFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :elements,        :viewable,     :boolean, default: true
    add_column :eventcategories, :confidential, :boolean, default: false
    add_column :events,          :confidential, :boolean, default: false
    add_column :settings,        :busy_string,  :string,  default: "Busy"
    add_column :concerns,        :assistant_to, :boolean, default: false
  end
end
