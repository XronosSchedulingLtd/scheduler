class CreateUserFormResponses < ActiveRecord::Migration[4.2]
  def change
    create_table :user_form_responses do |t|
      t.integer :user_form_id
      t.integer :parent_id
      t.string :parent_type
      t.integer :user_id
      t.text :form_data

      t.timestamps
    end
  end
end
