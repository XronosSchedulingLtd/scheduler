class AddJournalPrivilegeBit < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_view_journals, :boolean, default: false
  end
end
