class AddAllocations < ActiveRecord::Migration[5.2]
  def change
    create_table :ad_hoc_domain_allocations do |t|
      t.string :name
      t.integer :ad_hoc_domain_cycle_id
      t.text :allocations, limit: 65536
      t.timestamps
    end
    add_index :ad_hoc_domain_allocations, :ad_hoc_domain_cycle_id
  end
end
