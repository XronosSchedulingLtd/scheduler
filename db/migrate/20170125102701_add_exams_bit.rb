class AddExamsBit < ActiveRecord::Migration
  def change
    add_column :users, :exams, :boolean, default: false
  end
end
