class AddTimesToCommitments < ActiveRecord::Migration
  def change
    add_timestamps(:commitments)
  end
end
