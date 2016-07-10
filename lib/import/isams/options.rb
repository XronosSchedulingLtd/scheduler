
class Options

  attr_reader :timetable_name

  #
  #  These next two are intended to be over-ridden by MIS-specific
  #  versions.
  #
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
