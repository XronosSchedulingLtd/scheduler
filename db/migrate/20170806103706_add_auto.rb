class AddAuto < ActiveRecord::Migration
  def change
    add_column :properties, :auto_staff,  :boolean, default: false
    add_column :properties, :auto_pupils, :boolean, default: false
    reversible do |change|
      change.up do
        Property.all.each do |p|
          p.auto_staff = p.make_public
          p.auto_pupils = p.make_public
          p.save!
        end
      end
    end
  end
end
