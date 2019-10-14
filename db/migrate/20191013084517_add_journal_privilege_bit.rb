class AddJournalPrivilegeBit < ActiveRecord::Migration
  def change
    add_column :users, :can_view_journals, :boolean, default: false
  end
end
