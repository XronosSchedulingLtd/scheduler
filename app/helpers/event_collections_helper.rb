module EventCollectionsHelper

  MonthOptionTexts = {
    every_time:           "All",
    first_time:           "First",
    second_time:          "Second",
    third_time:           "Third",
    fourth_time:          "Forth",
    fifth_time:           "Fifth",
    last_time:            "Last",
    penultimate_time:     "Penultimate",
    antepenultimate_time: "Ante-penultimate"
  }
  MonthOptionTexts.default = "<unknown>"

  #
  #  The collection_select code needs an array of items which respond
  #  to two keys.
  #
  MonthOption = Struct.new(:key, :text)
  MonthOptions = MonthOptionTexts.collect {|key, text|
    MonthOption.new(key, text)
  }
  
  #
  #  Provides an array of objects suitable for creating the pop
  #  down list of when in a month something can occur.
  #
  def when_in_month_options
    MonthOptions
  end

  def when_in_month_text(when_in_month)
    MonthOptionTexts[when_in_month.to_sym]
  end

end
