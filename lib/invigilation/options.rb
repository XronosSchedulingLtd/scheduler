
class Options

  attr_reader :verbose,
              :quiet,
              :just_initialise,
              :do_timings,
              :start_date,
              :end_date,
              :summary,
              :clashes,
              :daily,
              :weekly,
              :weeks,
              :ahead

  def initialize
    @verbose         = false
    @weekly          = false
    @daily           = false
    @clashes         = false
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

      opts.on("--clashes",
              "Check for clashes between invigilations",
              "and other commitments.") do |clashes|
        @clashes = clashes
      end

      opts.on("--daily",
              "Do a day's worth of invigilation notices.") do |daily|
        @daily = daily
      end

      opts.on("--weekly",
              "Do a whole week's worth of invigilation",
              "notices.") do |weekly|
        @weekly = weekly
      end

    end.parse!
  end

end
