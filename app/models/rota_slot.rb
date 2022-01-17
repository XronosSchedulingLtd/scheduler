#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'tod'

class RotaSlotValidator < ActiveModel::Validator
  def validate(record)
    unless record[:starts_at].instance_of?(Tod::TimeOfDay)
      #
      #  Don't seem to have a start time.  Has any useful attempt
      #  been made?
      #
      if record.org_starts_at.blank?
        record.errors[:starts_at] << "can't be blank"
      else
        record.errors[:starts_at] << "don't understand #{record.org_starts_at}"
      end
    end
    unless record[:ends_at].instance_of?(Tod::TimeOfDay)
      #
      #  Don't seem to have an end time.  Has any useful attempt
      #  been made?
      #
      if record.org_ends_at.blank?
        record.errors[:ends_at] << "can't be blank"
      else
        record.errors[:ends_at] << "don't understand #{record.org_ends_at}"
      end
    end
    if record[:starts_at] && record[:ends_at]
      unless record[:starts_at] < record[:ends_at]
        record.errors[:ends_at] << "must be later than the start time"
      end
    end
  end

end

class RotaSlot < ApplicationRecord
  serialize :starts_at, Tod::TimeOfDay
  serialize :ends_at, Tod::TimeOfDay
  serialize :days, Array

  belongs_to :rota_template

  validates_with RotaSlotValidator

  attr_reader :org_starts_at, :org_ends_at

  #
  #  Slightly mis-named.  This is used solely to allow the JS front end to
  #  sort our slots correctly.  We want them sorted first by start time
  #  and then by end time, but the Backbone library expects to do things
  #  solely by a single value.
  #
  def start_second
    if self[:starts_at]
      if self[:ends_at]
        (self[:starts_at].second_of_day * 100000) + self[:ends_at].second_of_day
      else
        self[:starts_at].second_of_day * 100000
      end
    else
      0
    end
  end

  def starts_at
    #
    #  Coerce it to be a string.
    #
    stringify(:starts_at)
  end

  def ends_at
    stringify(:ends_at)
  end

  def starts_at_tod
    self[:starts_at]
  end

  def ends_at_tod
    self[:ends_at]
  end

  def starts_at=(value)
    @org_starts_at = value
    assign_tod_value(:starts_at, value)
  end

  def ends_at=(value)
    @org_ends_at = value
    assign_tod_value(:ends_at, value)
  end

  #
  #  Check whether this slot applies on a given date or day of the week.
  #  Can accept a Date-like thing (which responds to wday()) or an integer
  #  between 0 and 6.
  #
  def applies_on?(selector)
    if selector.respond_to?(:wday)
      self.days[selector.wday]
    elsif selector.kind_of?(Integer) &&
      selector >= 0 && selector <= 6
      self.days[selector]
    else
      nil
    end
  end

  #
  #  Construct a starts_at and ends_at for this slot on the indicated
  #  date.  Need to test that tod copes with timezones and DST correctly.
  #  Seems to.
  #
  def timings_for(date)
    return [self[:starts_at].on(date), self[:ends_at].on(date)]
  end

  #
  #  Passed a block, this will yield all the entries in this rota_slot
  #  as individual periods.
  #
  def periods
    0.upto(6) do |i|
      if self.days[i]
        yield i, self.starts_at, self.ends_at
      end
    end
  end

  def <=>(other)
    if other.instance_of?(RotaSlot)
      if self.starts_at == other.starts_at
        self.ends_at <=> other.ends_at
      else
        self.starts_at <=> other.starts_at
      end
    else
      nil
    end
  end

  def duration
    self[:ends_at] - self[:starts_at]
  end

  def num_days
    self.days.count(true)
  end

  def minutes
    ((self[:ends_at].second_of_day -
      self[:starts_at].second_of_day) / 60) * num_days
  end

  private

  def assign_tod_value(field, value)
    if value.instance_of?(Tod::TimeOfDay)
      self[field] = value
    elsif value.instance_of?(ActiveSupport::TimeWithZone)
      self[field] = Tod::TimeOfDay.try_parse(value.strftime("%H:%M"))
    elsif value.instance_of?(String)
      self[field] = Tod::TimeOfDay.try_parse(value)
    else
      raise "Can't assign #{value.class} to #{:field}."
    end
  end

  def stringify(field)
    if self[field]
      self[field].strftime("%H:%M")
    else
      ""
    end
  end

end
