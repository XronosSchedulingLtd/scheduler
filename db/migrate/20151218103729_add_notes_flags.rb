class AddNotesFlags < ActiveRecord::Migration
  def change
    add_column :itemreports, :note_flags, :string, :default => ""
  end
end
