class AddRepetitionFlag < ActiveRecord::Migration
  def change
    add_column :users, :can_repeat_events, :boolean, default: false
  end
end
