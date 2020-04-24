class AddExamsBit < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :exams, :boolean, default: false
  end
end
