
class Options

  attr_reader :timetable_name, :do_check

  def more_defaults
    @timetable_name = nil
    @do_check = false
  end

  def more_options(opts)
    opts.on("-t", "--timetable [TIMETABLE NAME]",
            "Specify the name of the timetable to use.") do |t|
      @timetable_name = t
    end

  end
end
