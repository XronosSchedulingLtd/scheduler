class Date

  public

  def start_time
    self.at_beginning_of_day
  end

  def end_time
    (self + 1.day).at_beginning_of_day
  end

  def fulsome_format
    self.strftime("%a #{self.day.ordinalize} %b, %Y")
  end

  def compact_format
    self.strftime("%a #{self.day.ordinalize} %b")
  end

  def self.safe_parse(value, default = nil)
    Date.parse(value.to_s)
  rescue ArgumentError
    default
  end

  #
  #  The date of the Sunday before (or on) the given date.
  #
  def sundate
    self - self.wday
  end
end
