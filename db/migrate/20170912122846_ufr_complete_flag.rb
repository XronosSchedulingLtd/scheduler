class UfrCompleteFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :user_form_responses, :complete, :boolean, default: false
  end
end
