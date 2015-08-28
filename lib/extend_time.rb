class ActiveSupport::TimeWithZone

  public

  def noon?
    self.hour == 12 && self.min == 0 && self.sec == 0
  end

  def midnight?
    self.hour == 0 && self.min == 0 && self.sec == 0
  end

  def morning?
    self.hour < 12
  end

  #
  #  Turn two times into a neat interval string.
  #
  def neat_str(ampm, force_mins = false)
    if self.noon?
      "12 noon"
    elsif self.midnight?
      "12 midnight"
    else
      format_str =
        "%-l#{ self.min != 0 || force_mins ? ":%M" : ""}#{ampm ? " %P" : ""}"
      self.strftime(format_str)
    end
  end

  def interval_str(end_time = nil, twelve_hour = false)
    if self == end_time || end_time == nil
      if twelve_hour
        self.neat_str(true)
      else
        self.strftime("%H:%M")
      end
    else
      #
      #  Two distinct times to handle.
      #
      if twelve_hour
        force_mins = self.min != 0 || end_time.min != 0
        ampm = (self.morning? != end_time.morning?) ||
               self.noon? || self.midnight?
        "#{self.neat_str(ampm, force_mins)} - #{end_time.neat_str(true, force_mins)}"
      else
        "#{self.strftime("%H:%M")} - #{end_time.strftime("%H:%M")}"
      end
    end
  end

end


