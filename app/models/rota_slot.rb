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
      #  Don't seem to have a start time.  Has any useful attempt
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

class RotaSlot < ActiveRecord::Base
  serialize :starts_at, Tod::TimeOfDay
  serialize :ends_at, Tod::TimeOfDay
  serialize :days, Array

  belongs_to :rota_template

  validates :rota_template, :presence => true
  validates_with RotaSlotValidator

  attr_reader :org_starts_at, :org_ends_at

  def start_second
    if self[:starts_at]
      self[:starts_at].second_of_day
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

  def starts_at=(value)
    @org_starts_at = value
    assign_tod_value(:starts_at, value)
  end

  def ends_at=(value)
    @org_ends_at = value
    assign_tod_value(:ends_at, value)
  end

  private

  def assign_tod_value(field, value)
    if value.instance_of?(Tod::TimeOfDay)
      self[field] = value
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
