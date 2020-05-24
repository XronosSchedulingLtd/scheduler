class CreateProtoEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :proto_events do |t|
      t.text :body
      t.date :starts_on
      t.date :ends_on
      t.belongs_to :eventcategory, :index => true
      t.belongs_to :eventsource,   :index => true
      t.belongs_to :rota_template, :index => true
      t.references :generator, :polymorphic => true, :index => true

      t.timestamps
    end
  end
end
