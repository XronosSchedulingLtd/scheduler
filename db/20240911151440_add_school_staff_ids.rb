class AddSchoolStaffIds < ActiveRecord::Migration[5.2]
    def change
      add_column :pupils, :school_id, :string, default: "", null: false
      add_column :staffs, :user_code, :string, default: "", null: false
    end
  end