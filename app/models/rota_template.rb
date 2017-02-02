class RotaTemplate < ActiveRecord::Base
  has_many :rota_slots, :dependent => :destroy

  #
  #  Make a copy of ourself, duplicating all the necessary rota slots.
  #
  def do_clone
    new_template = RotaTemplate.new(name: "Clone of #{self.name}")
    if new_template.save
      self.rota_slots.each do |rs|
        new_template.rota_slots << rs.dup
      end
    end
    new_template
  end

end
