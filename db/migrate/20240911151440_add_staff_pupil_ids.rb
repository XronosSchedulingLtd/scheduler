class AddStaffPupilIds < ActiveRecord::Migration[5.2]
  def change
    add_column :pupils, :school_id, :string, default: "", null: false
    add_index :pupils, :school_id
    add_column :staffs, :user_code, :string, default: "", null: false
    add_index :staffs, :user_code
  end
end
