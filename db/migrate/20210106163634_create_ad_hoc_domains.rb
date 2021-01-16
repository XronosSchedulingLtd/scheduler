class CreateAdHocDomains < ActiveRecord::Migration[5.2]
  def change
    create_table :ad_hoc_domains do |t|
      t.string :name
      t.integer :eventsource_id
      t.integer :eventcategory_id
      t.integer :connected_property_id
      t.integer :default_day_shape_id
      t.integer :datasource_id
      t.timestamps
    end

    create_table :ad_hoc_domain_controllers do |t|
      t.integer :ad_hoc_domain_id
      t.integer :user_id
      t.timestamps
    end

    add_index :ad_hoc_domain_controllers, :ad_hoc_domain_id
    add_index :ad_hoc_domain_controllers, :user_id

    create_table :ad_hoc_domain_subjects do |t|
      t.integer :ad_hoc_domain_id
      t.integer :subject_id
      t.timestamps
    end
    add_index :ad_hoc_domain_subjects, :ad_hoc_domain_id
    add_index :ad_hoc_domain_subjects, :subject_id

    create_table :ad_hoc_domain_staffs do |t|
      t.integer :staff_id
      t.integer :ad_hoc_domain_subject_id
      t.timestamps
    end
    add_index :ad_hoc_domain_staffs, :staff_id
    add_index :ad_hoc_domain_staffs, :ad_hoc_domain_subject_id

    create_table :ad_hoc_domain_pupil_courses do |t|
      t.integer :pupil_id
      t.integer :ad_hoc_domain_staff_id
      t.integer :lessons_per_week, default: 1
      t.timestamps
    end
    add_index :ad_hoc_domain_pupil_courses, :pupil_id
    add_index :ad_hoc_domain_pupil_courses, :ad_hoc_domain_staff_id

  end
end
