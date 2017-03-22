class NotesDefaultVisible < ActiveRecord::Migration
  def change
    change_column_default :notes, :visible_staff, true
  end
end
