
class Options

  attr_reader :verbose,
              :quiet,
              :full_load,
              :just_initialise,
              :send_emails,
              :do_timings,
              :era,
              :start_date,
              :ahead,
              :do_convert,
              :check_recurring,
              :activities,
              :cover,
              :dont_do

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
    @quiet           = false
    @check_recurring = false
    @activities      = false
    @cover           = false
    @era             = nil
    @start_date      = nil
    @ahead           = 0
    @do_convert      = false
    @dont_do         = []
    more_defaults
    OptionParser.new do |opts|
      opts.banner = "Usage: misimport.rb [options]"

      opts.on("-i", "--initialise", "Initialise only") do |i|
        @just_initialise = i
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @verbose = v
      end

      opts.on("-q", "--quiet", "Run particularly quietly") do |q|
        @quiet = q
      end

      opts.on("-c", "--check",
              "Check the YAML files used for recurring",
              "events and report any problems.  Do no",
              "further processing.") do |c|
        @check_recurring = c
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
              "Log the time at various stages in the",
              "processing.") do |timings|
        @do_timings = timings
      end

      opts.on("-s", "--start [DATE]", Date,
              "Specify an over-riding start date",
              "for loading events and groups.") do |date|
        @start_date = date
      end

      opts.on("-a", "--ahead [YEARS]", Integer,
              "When loading data ahead of time, that is -",
              "loading data for next year before the MIS",
              "has been rolled over, add this value to",
              "pupils' year numbers etc.") do |years|
        @ahead = years
      end

      opts.on("--cover",
              "Attempt to load cover slots") do |cover|
        @cover = cover
      end

      opts.on("--activities",
              "Load information about extra-curricular",
              "activities") do |activities|
        @activities = activities
      end

      opts.on("--convert",
              "Convert record IDs from a previous MIS") do |c|
        @do_convert = c
      end

      opts.on("-n", "--no [THINGS]", String,
              "Specify things not to do/load",
              "Currently just \"setlists\".") do |things|
        broken = things.split(",")
        broken.each do |thing|
          case thing.upcase
          when "SETLISTS"
            @dont_do << :setlists unless @dont_do.include? :setlists
          else
            puts "Don't understand \"#{thing}\" as something not to do."
          end
        end
      end

      more_options(opts)

    end.parse!
  end

end
