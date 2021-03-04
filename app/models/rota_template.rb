#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class RotaTemplate < ApplicationRecord

  class Slot < Hash
    #
    #  Provides a simplified representation of a RotaSlot, suitable
    #  for transmission as JSON.
    #
    def self.from_rs(rs)
      slot = self.new
      slot[:starts_at] = rs.starts_at
      slot[:ends_at]   = rs.ends_at
      #
      #  Need to duplicate the array because otherwise the client just
      #  gets a pointer to our existing array and any modifications will
      #  get silently written back to our copy.
      #
      slot[:days]      = rs.days.dup
      slot
    end

    #
    #  Perform initial validation of proposed data for a rota slot.
    #  Raise an informative error if it isn't.
    #
    def self.validate(sd, i)
      matcher = /\A\d\d:\d\d\z/

      if sd[:starts_at].nil? || sd[:ends_at].nil? || sd[:days].nil?
        raise ArgumentError.new("Slot #{i} is invalid. Must have starts_at, ends_at, days.")
      end
      unless sd[:starts_at].instance_of?(String) &&
          sd[:ends_at].instance_of?(String) &&
          sd[:days].instance_of?(Array)
        raise ArgumentError.new("Slot #{i} is invalid. Wrong argument type(s).")
      end
      unless matcher.match(sd[:starts_at]) && matcher.match(sd[:ends_at])
        raise ArgumentError.new("Slot #{i} is invalid. Badly formatted times.")
      end
    end

    def self.normalize_days(days)
      #
      #  Given an array of days, cut it down to 7 entries,
      #  or pad it out to same.
      #
      (days + [false, false, false, false, false, false, false]).take(7)
    end

  end

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

  has_one :ad_hoc_domain_staff,
          dependent: :nullify

  #
  #  We may be the default day shape for one or more ad hoc domains.
  #
  has_many :ad_hoc_domain_defaults,
           class_name: :AdHocDomain,
           foreign_key: :default_day_shape_id,
           dependent: :nullify

  validates :name,               :presence => true

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
    relevant_slots = self.rota_slots.select{|rs| rs.applies_on?(date)}
    if block_given?
      relevant_slots.each do |rs|
        yield rs
      end
    end
    relevant_slots
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
  #  Methods to allow the set of slots to be read and altered all in one
  #  go.
  #
  #  We provide an expect an array of hashes, each of which has the
  #  following attributes:
  #
  #  starts_at  text  "10:00"
  #  ends_at    text  "11:15"
  #  days       array [false, true, true, true, true, true, false]
  #
  #  The array represents the days of the week from Sun to Sat.  If
  #  passed fewer than 7 entries we assume the others are false.  For more
  #  than 7 we ignore the rest.
  #
  #  When assigned a set of slots we make every effort to ensure our
  #  database update is atomic.  We will either do the whole update or
  #  throw an exception.
  #
  def slots
    self.rota_slots.sort.collect {|rs| Slot.from_rs(rs)}
  end

  def slots=(slot_defs)
    #
    #  A bit of validation first.
    #
    unless slot_defs.instance_of?(Array)
      raise ArgumentError.new("Expected array of slot definitions.")
    end

    slot_defs.each_with_index do |sd, i|
      #
      #  Note that this method raises an error if the definition is not
      #  valid.
      #
      Slot.validate(sd, i)
      #
      #  And make sure it will actually generate a rota slot.
      #
      #  Tempting to use:
      #
      #  rs = self.rota_slots.new(sd)
      #
      #  but that then adds our new rota slot to our array and we intend
      #  it to be merely temporary.  Instead use:
      #
      rs = RotaSlot.new(sd.merge({rota_template: self}))
      unless rs.valid?
        #
        #  This is messy, but...
        #
        #  If it's invalid then there must be an error.  Grab the first,
        #  in the form of an array.  The first element (0) of the array is
        #  the field key, whilst the second (1) is an array of textual
        #  messages of which we take the first (0).
        #
        message = "#{rs.errors.messages.first[0]}: #{rs.errors.messages.first[1][0]}"
        raise ArgumentError.new(message)
      end
    end
    #
    #  Willing to attempt the actual work.  Done in a transaction so that
    #  if anything goes wrong then nothing happens.
    #
    #  As far as possible, we try to preserve existing RotaSlot records.
    #  This would all be much simpler if we got rid of RotaSlots entirely
    #  and did everything within a serialized field in the RotaTemplate.
    #
    self.transaction do
      existing_slots = self.rota_slots.to_a
      slot_defs.each do |sd|
        existing = existing_slots.detect {|es| es.starts_at == sd[:starts_at] &&
                                               es.ends_at == sd[:ends_at]}
        if existing
          #
          #  Already have a suitable slot.  Amend the days if needs be.
          #
          proposed_days = Slot.normalize_days(sd[:days])
          if proposed_days != Slot.normalize_days(existing.days)
            existing.days = proposed_days
            existing.save!
          end
          #
          #  Remove that slot for the in memory list to prevent it
          #  being deleted from the d/b.
          #
          existing_slots.delete(existing)
        else
          #
          #  Need to create a new slot.
          #
          self.rota_slots.create!(sd)
        end
      end
      #
      #  Get rid of any remaining existing slots
      #
      existing_slots.each do |es|
        self.rota_slots.destroy(es)
      end
    end
  end
end
