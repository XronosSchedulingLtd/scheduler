
class Options

  attr_reader :verbose,
              :full_load,
              :just_initialise,
              :send_emails,
              :do_timings,
              :era,
              :start_date

  #
  #  These next two are intended to be over-ridden by MIS-specific
  #  versions.
  #
  def more_defaults
  end

  def more_options(opts)
  end

  def initialize
    @verbose         = false
    @full_load       = false
    @just_initialise = false
    @send_emails     = false
    @do_timings      = false
    @era             = nil
    @start_date      = nil
    more_defaults
    OptionParser.new do |opts|
      opts.banner = "Usage: misimport.rb [options]"

      opts.on("-i", "--initialise", "Initialise only") do |i|
        @just_initialise = i
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @verbose = v
      end

      opts.on("-f", "--full",
              "Do a full load",
              "(as opposed to incremental.  Doesn't",
              "actually affect what gets loaded, but",
              "does affect when it's loaded from.)") do |f|
        @full_load = f
      end

      opts.on("-e", "--era [ERA NAME]",
              "Specify the era to load data into.") do |era|
        @era = era
      end

      opts.on("--email",
              "Generate e-mails about cover issues.") do |email|
        @send_emails = email
      end

      opts.on("--timings",
              "Log the time at various stages in the processing.") do |timings|
        @do_timings = timings
      end

      opts.on("-s", "--start [DATE]", Date,
              "Specify an over-riding start date",
              "for loading events and groups.") do |date|
        @start_date = date
      end

      more_options(opts)

    end.parse!
  end

end
