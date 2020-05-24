class NotesDefaultVisible < ActiveRecord::Migration[4.2]
  def change
    change_column_default :notes, :visible_staff, true
  end
end
