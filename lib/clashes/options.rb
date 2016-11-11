
class Options

  attr_reader :verbose,
              :quiet,
              :just_initialise,
              :do_timings,
              :start_date,
              :end_date,
              :summary,
              :weekly,
              :weeks

  def initialize
    @verbose         = false
    @just_initialise = false
    @do_timings      = false
    @quiet           = false
    @summary         = false
    @weekly          = false
    @start_date      = Date.today
    @weeks           = 1
    @end_date        = nil
    OptionParser.new do |opts|
      opts.banner = "Usage: clashcheck.rb [options]"

      opts.on("-i", "--initialise", "Initialise only") do |i|
        @just_initialise = i
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @verbose = v
      end

      opts.on("-q", "--quiet", "Run particularly quietly") do |q|
        @quiet = q
      end

      opts.on("--timings",
              "Log the time at various stages in the",
              "processing.") do |timings|
        @do_timings = timings
      end

      opts.on("-s", "--start [DATE]", Date,
              "Specify a start date (default: today)") do |date|
        @start_date = date
      end

      opts.on("-e", "--end [DATE]", Date,
              "Specify an end date (default: none)") do |date|
        @end_date = date
      end

      opts.on("-w", "--weeks [NUMBER]", Integer,
              "How many weeks to process (default: 2)") do |number|
        @weeks = number
      end

      opts.on("--summary",
              "Instead of doing the actual clash",
              "checking, generate summary e-mails",
              "for those who have requested them.") do |summary|
        @summary = summary
      end

      opts.on("--weekly",
              "Do a weekly summary, rather than a",
              "daily one.") do |weekly|
        @weekly = weekly
      end

    end.parse!
  end

end
