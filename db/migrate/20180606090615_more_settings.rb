class MoreSettings < ActiveRecord::Migration
  def change
    add_column :settings, :tutorgroups_by_house,     :boolean, default: true
    add_column :settings, :tutorgroups_name,         :string,  default: "Tutor group"
    add_column :settings, :tutor_name,               :string,  default: "Tutor"
    add_column :settings, :prep_suffix,              :string,  default: " (P)"
    add_column :settings, :prep_property_element_id, :integer, default: nil
    add_column :settings, :ordinalize_years,         :boolean, default: true
    add_column :pupils,   :house_name,               :string,  default: ""
    reversible do |change|
      change.up do
        Setting.set_prep_property
        Pupil.import_houses
      end
    end
  end
end
