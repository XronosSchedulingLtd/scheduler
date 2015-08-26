class Date

  public

  def start_time
    self.at_beginning_of_day
  end

  def end_time
    (self + 1.day).at_beginning_of_day
  end

end
