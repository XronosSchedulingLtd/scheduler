class AddRepeatingToJournal < ActiveRecord::Migration[4.2]
  def change
    add_column :journal_entries, :repeating, :boolean, default: false
  end
end
