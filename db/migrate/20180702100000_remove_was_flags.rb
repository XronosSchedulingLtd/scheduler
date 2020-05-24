class RemoveWasFlags < ActiveRecord::Migration[4.2]
  def change
    remove_column :commitments,         :was_rejected
    remove_column :commitments,         :was_constraining
    remove_column :user_form_responses, :was_complete
  end
end
