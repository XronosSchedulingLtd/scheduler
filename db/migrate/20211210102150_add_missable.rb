class AddMissable < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :missable, :boolean, default: false
    add_column :ad_hoc_domains, :missable_threshold, :integer, default: 6
    add_column :ad_hoc_domain_allocations, :scores, :text, limit: 65536
  end
end
