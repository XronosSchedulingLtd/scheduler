class CreateAdHocDomains < ActiveRecord::Migration[5.2]
  def change
    create_table :ad_hoc_domains do |t|
      t.string :name
      t.integer :eventsource_id
      t.integer :eventcategory_id
      t.integer :connected_property_element_id
      t.integer :default_day_shape_id
      t.timestamps
    end

    create_table :ad_hoc_domain_controllers do |t|
      t.integer :ad_hoc_domain_id
      t.integer :user_id
    end

    add_index :ad_hoc_domain_controllers, :ad_hoc_domain_id
    add_index :ad_hoc_domain_controllers, :user_id
  end
end
