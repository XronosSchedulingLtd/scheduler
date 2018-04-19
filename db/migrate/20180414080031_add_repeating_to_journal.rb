class AddRepeatingToJournal < ActiveRecord::Migration
  def change
    add_column :journal_entries, :repeating, :boolean, default: false
  end
end
