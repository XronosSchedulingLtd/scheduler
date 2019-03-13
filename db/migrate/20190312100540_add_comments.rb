class AddComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.references :parent, polymorphic: true, index: true
      t.references :user, index: true
      t.text       :body
      t.timestamps
    end
  end
end
