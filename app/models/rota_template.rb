class RotaTemplate < ActiveRecord::Base

  belongs_to :rota_template_type

  has_many :rota_slots, :dependent => :destroy

  has_many :exam_cycles,
           :dependent => :nullify,
           :foreign_key => :default_rota_template_id

  has_many :proto_events,
           :dependent => :nullify
  has_many :users, foreign_key: :day_shape_id, :dependent => :nullify

  has_one  :setting_for_display,
           class_name: :Setting,
           foreign_key: :default_display_day_shape_id,
           dependent: :nullify
  has_one  :setting_for_free_finder,
           class_name: :Setting,
           foreign_key: :default_free_finder_day_shape_id,
           dependent: :nullify

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
  #  Provide our first slot which contains the indicated time
  #  on the corresponding date.
  #
  #  Nil if we don't have one.
  #
  def slot_for(datetime)
    the_date = datetime.to_date
    slots_for(the_date) do |rs|
      starts_at, ends_at = rs.timings_for(the_date)
      if datetime >= starts_at && datetime < ends_at
        return rs
      end
    end
    return nil
  end

  def snap_to_period(datetime)
    slot = slot_for(datetime)
    if slot
      slot.timings_for(datetime.to_date)
    else
      return datetime, datetime
    end
  end

  def periods(&block)
    self.rota_slots.each do |rs|
      rs.periods(&block)
    end
  end

  #
  #  A maintenance method to update all existing rota templates and
  #  link them to a type.  They are all Invigilation ones.
  #
  def self.make_all_invigilation
    rtt = RotaTemplateType.find_by(name: "Invigilation")
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
