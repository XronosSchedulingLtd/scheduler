class AddEmailSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :dns_domain_name, :string, :default => ""
    add_column :settings, :from_email_address, :string, :default => ""
  end
end
