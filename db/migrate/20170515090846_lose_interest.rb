class LoseInterest < ActiveRecord::Migration
  def change
    drop_table :interests
  end
end
