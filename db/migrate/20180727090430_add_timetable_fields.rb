class AddTimetableFields < ActiveRecord::Migration[4.2]
  def change
    add_column :eventcategories, :timetable, :boolean, default: false
    add_column :settings,        :first_tt_day,    :integer, default: 1
    add_column :settings,        :last_tt_day,     :integer, default: 5
    add_column :settings,        :tt_cycle_weeks,  :integer, default: 2
    add_column :settings,        :tt_prep_letter,  :string,  default: "P", limit: 2
    add_column :settings,        :tt_store_start,  :date,    default: "2006-01-01"
  end
end
