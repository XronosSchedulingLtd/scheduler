class CreateUserForms < ActiveRecord::Migration[4.2]
  def change
    create_table :user_forms do |t|
      t.string  :name
      t.integer :created_by_user_id
      t.integer :edited_by_user_id
      t.text    :definition

      t.timestamps
    end
    add_column :users, :can_has_forms, :boolean, default: false
  end
end
