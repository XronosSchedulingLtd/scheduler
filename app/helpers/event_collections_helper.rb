module EventCollectionsHelper

  MonthOption = Struct.new(:key, :text)
  MonthOptions = [
    MonthOption.new(:every_time,           "All"),
    MonthOption.new(:first_time,           "First"),
    MonthOption.new(:second_time,          "Second"),
    MonthOption.new(:third_time,           "Third"),
    MonthOption.new(:fourth_time,          "Forth"),
    MonthOption.new(:fifth_time,           "Fifth"),
    MonthOption.new(:last_time,            "Last"),
    MonthOption.new(:penultimate_time,     "Penultimate"),
    MonthOption.new(:antepenultimate_time, "Ante-penultimate")
  ]
  
  #
  #  Provides an array of objects suitable for creating the pop
  #  down list of when in a month something can occur.
  #
  def when_in_month_options
    MonthOptions
  end
end
