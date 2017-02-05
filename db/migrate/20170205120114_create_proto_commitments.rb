class CreateProtoCommitments < ActiveRecord::Migration
  def change
    create_table :proto_commitments do |t|
      t.belongs_to :proto_event, :index => true
      t.belongs_to :element,     :index => true

      t.timestamps
    end
  end
end
