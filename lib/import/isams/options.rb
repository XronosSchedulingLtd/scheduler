
class Options

  attr_reader :timetable_name

  def more_defaults
    @timetable_name = nil
  end

  def more_options(opts)
    opts.on("-t", "--timetable [TIMETABLE NAME]",
            "Specify the name of the timetable to use.") do |t|
      @timetable_name = t
    end
  end
end
