class EnhanceCycle < ActiveRecord::Migration[5.2]
  def change
    add_column :ad_hoc_domain_cycles, :lock_version,  :integer, default: 0, null: false
    add_column :ad_hoc_domain_cycles, :update_status, :integer, default: 0
    add_column :ad_hoc_domain_cycles, :active_allocation_id, :integer, default: nil
    add_column :ad_hoc_domain_cycles, :queued_at, :datetime, default: nil
    add_column :ad_hoc_domain_cycles, :started_at, :datetime, default: nil
    add_column :ad_hoc_domain_cycles, :finished_at, :datetime, default: nil
    add_column :ad_hoc_domain_cycles, :num_created, :integer, default: 0
    add_column :ad_hoc_domain_cycles, :num_deleted, :integer, default: 0
    add_column :ad_hoc_domain_cycles, :num_amended, :integer, default: 0
    add_column :ad_hoc_domain_cycles, :percentage_done, :float, default: 0.0
  end
end
