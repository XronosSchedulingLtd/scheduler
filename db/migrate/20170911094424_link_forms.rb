class LinkForms < ActiveRecord::Migration
  def change
    add_column :elements, :user_form_id, :integer, :default => nil
  end
end
