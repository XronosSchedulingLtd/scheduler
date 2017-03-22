class RotaTemplate < ActiveRecord::Base
  has_many :rota_slots, :dependent => :destroy

  has_many :exam_cycles,
           :dependent => :nullify,
           :foreign_key => :default_rota_template_id

  has_many :proto_events,
           :dependent => :nullify

  validates :name, :presence => true

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

  def <=>(other)
    self.name <=> other.name
  end

  #
  #  Provide all of our slots which apply on the relevant date.
  #
  def slots_for(date)
    self.rota_slots.select{|rs| rs.applies_on?(date)}.each do |rs|
      yield rs
    end
  end
end