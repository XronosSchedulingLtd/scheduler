class AddTimesToCommitments < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:commitments)
  end
end
