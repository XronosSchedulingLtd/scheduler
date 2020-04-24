class AddCorrespondingStaff < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :corresponding_staff_id, :integer
    reversible do |change|
      change.up do
        User.populate_corresponding_staff
      end
    end
  end
end
