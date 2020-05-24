class AddRepetitionFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_repeat_events, :boolean, default: false
  end
end
