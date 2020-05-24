class LoseInterest < ActiveRecord::Migration[4.2]
  def change
    drop_table :interests
  end
end
