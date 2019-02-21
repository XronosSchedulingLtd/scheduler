class AddEmailFields < ActiveRecord::Migration
  def change
    add_column :resourcegrouppersonae, :confirmation_days, :integer, default: 0
    add_column :resourcegrouppersonae, :form_warning_days, :integer, default: 0

    add_column :users, :confirmation_messages, :boolean, default: true
    add_column :users, :prompt_for_forms, :boolean, default: true

    add_column :requests, :reconfirmed, :boolean, default: false
  end
end
