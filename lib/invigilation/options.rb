
class Options

  attr_reader :verbose,
              :quiet,
              :just_initialise,
              :do_timings,
              :start_date,
              :end_date,
              :summary,
              :weekly,
              :weeks,
              :ahead

  def initialize
    @verbose         = false
    @weekly          = false
    @start_date      = Date.today
    OptionParser.new do |opts|
      opts.banner = "Usage: options.rb [options]"

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @verbose = v
      end

      opts.on("-s", "--start [DATE]", Date,
              "Specify a start date (default: today)") do |date|
        @start_date = date
      end

      opts.on("--weekly",
              "Do a whole week's worth of invigilation.") do |weekly|
        @weekly = weekly
      end

    end.parse!
  end

end
