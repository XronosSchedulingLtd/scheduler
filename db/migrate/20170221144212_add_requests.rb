class AddRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :requests do |t|
      t.belongs_to :event,         :index => true
      t.belongs_to :element,       :index => true
      t.belongs_to :proto_request, :index => true
      t.integer    :quantity,      :default => 1

      t.timestamps
    end
  end
end
