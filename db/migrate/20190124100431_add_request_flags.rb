class AddRequestFlags < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :tentative,    :boolean, default: true
    add_column :requests, :constraining, :boolean, default: false
    reversible do |change|
      change.up do
        Request.set_initial_flags
      end
    end
  end
end
