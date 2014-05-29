class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.date    :starts_on,  :null => false
      t.date    :ends_on

      t.timestamps
    end
  end
end
