class AddNotesFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :itemreports, :note_flags, :string, :default => ""
  end
end
