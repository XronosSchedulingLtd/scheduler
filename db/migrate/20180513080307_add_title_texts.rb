class AddTitleTexts < ActiveRecord::Migration
  def change
    add_column :settings, :title_text,        :string, default: nil
    add_column :settings, :public_title_text, :string, default: nil
    reversible do |change|
      change.up do
        Setting.set_title_texts
      end
    end
  end
end
