class AddMarkdownToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :formatted_contents, :text
    reversible do |change|
      change.up do
        Note.format_all_contents
      end
    end
  end
end
