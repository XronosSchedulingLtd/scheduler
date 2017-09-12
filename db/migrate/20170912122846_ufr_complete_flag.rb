class UfrCompleteFlag < ActiveRecord::Migration
  def change
    add_column :user_form_responses, :complete, :boolean, default: false
  end
end
