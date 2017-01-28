require 'tod'

class RotaSlot < ActiveRecord::Base
  serialize :starts_at, Tod::TimeOfDay
  serialize :ends_at, Tod::TimeOfDay
  serialize :days, Array

  belongs_to :rota_template

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
    assign_tod_value(:starts_at, value)
  end

  def ends_at=(value)
    assign_tod_value(:ends_at, value)
  end

  private

  def assign_tod_value(field, value)
    if value.instance_of?(Tod::TimeOfDay)
      self[field] = value
    elsif value.instance_of?(String)
      self[field] = Tod::TimeOfDay.parse(value)
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
