class LinkForms < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :user_form_id, :integer, :default => nil
  end
end
