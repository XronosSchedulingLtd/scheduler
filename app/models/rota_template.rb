class RotaTemplate < ActiveRecord::Base

  belongs_to :rota_template_type

  has_many :rota_slots, :dependent => :destroy

  has_many :exam_cycles,
           :dependent => :nullify,
           :foreign_key => :default_rota_template_id

  has_many :proto_events,
           :dependent => :nullify
  has_many :users, foreign_key: :day_shape_id, :dependent => :nullify

  validates :name,               :presence => true
  validates :rota_template_type, :presence => true

  #
  #  Make a copy of ourself, duplicating all the necessary rota slots.
  #
  def do_clone
    new_template = RotaTemplate.new({
      name: "Clone of #{self.name}",
      rota_template_type: self.rota_template_type
    })
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

  #
  #  A maintenance method to update all existing rota templates and
  #  link them to a type.  They are all Invigilation ones.
  #
  def self.make_all_invigilation
    rtt = RotaTemplateType.find(name: "Invigilation")
    if rtt
      RotaTemplate.all.each do |rt|
        unless rt.rota_template_type
          rt.rota_template_type = rtt
          rt.save!
        end
      end
    else
      puts "Can't find RotaTemplateType \"Invigilation\"."
    end
    nil
  end

end
