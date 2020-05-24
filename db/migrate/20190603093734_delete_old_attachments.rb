class DeleteOldAttachments < ActiveRecord::Migration[4.2]
  def change
    drop_table :attachments
  end
end
