class CreateEventcategories < ActiveRecord::Migration
  def change
    create_table :eventcategories do |t|
      t.string :name
      t.integer :pecking_order
      t.boolean :schoolwide
      t.boolean :publish
      t.boolean :public
      t.boolean :for_users
      t.boolean :unimportant

      t.timestamps
    end
  end
end
