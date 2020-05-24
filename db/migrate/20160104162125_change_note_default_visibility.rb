class ChangeNoteDefaultVisibility < ActiveRecord::Migration[4.2]
  def change
    change_column_default :attachments, :visible_staff, false
    change_column_default :notes, :visible_staff, false
  end
end
