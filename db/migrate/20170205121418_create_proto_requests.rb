class CreateProtoRequests < ActiveRecord::Migration
  def change
    create_table :proto_requests do |t|
      t.belongs_to :proto_event, :index => true
      t.belongs_to :element,     :index => true
      t.integer :quantity

      t.timestamps
    end
  end
end
