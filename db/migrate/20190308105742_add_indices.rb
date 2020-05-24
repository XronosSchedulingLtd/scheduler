class AddIndices < ActiveRecord::Migration[4.2]
  def change
    add_index :ahoy_messages, [:user_type, :user_id]
    add_index :elements, [:entity_type, :entity_id]
    add_index :groups, [:persona_type, :persona_id]
    add_index :notes, [:parent_type, :parent_id]
    add_index :user_form_responses, [:parent_type, :parent_id]
  end
end
