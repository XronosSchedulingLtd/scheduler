module EventCollectionsHelper

  MonthOption = Struct.new(:key, :text)
  MonthOptions = [
    MonthOption.new(:every_time,           "All"),
    MonthOption.new(:first_time,           "First occurrence"),
    MonthOption.new(:second_time,          "Second occurrence"),
    MonthOption.new(:third_time,           "Third occurrence"),
    MonthOption.new(:fourth_time,          "Forth occurrence"),
    MonthOption.new(:fifth_time,           "Fifth occurrence"),
    MonthOption.new(:last_time,            "Last occurrence"),
    MonthOption.new(:penultimate_time,     "Penultimate occurrence"),
    MonthOption.new(:antepenultimate_time, "Ante-penultimate occurrence")
  ]
  
  #
  #  Provides an array of objects suitable for creating the pop
  #  down list of when in a month something can occur.
  #
  def when_in_month_options
    MonthOptions
  end
end
