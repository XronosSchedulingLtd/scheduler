class AddFormStatus < ActiveRecord::Migration
  def change
    add_column :user_form_responses, :status, :integer, default: 0
    rename_column :user_form_responses, :complete, :was_complete
    reversible do |change|
      change.up do
        UserFormResponse.populate_statuses
      end
    end

  end
end
