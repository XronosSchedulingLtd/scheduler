require 'optparse'
require 'optparse/date'

class Options
  attr_reader :event_category_name, :verbose, :start_date, :end_date

  def initialize
    @event_category_name = "Lesson"
    @verbose = false
    @start_date = nil
    @end_date  = nil

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: music_import.rb [options]"

      opts.on("-c", "--category [EVENTCATEGORY]",
              "Specify the name of the event category",
              "to be used for all the fixtures.",
              "Defaults to \"Music\".") do |name|
        @event_category_name = name
      end

      opts.on("-s", "--start_date [DATE]", "Specify the start date (e.g. 2024-09-05)") do |date|
        @start_date = Date.parse(date)
      end

      opts.on("-e", "--end_date [DATE]", "Specify the end date (e.g. 2024-09-06)") do |date|
        @end_date = Date.parse(date)
      end

      opts.on("-v", "--verbose",
              "Run with verbose output") do
        @verbose = true
      end

      opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    parse_options(parser)
  end

  private

  def parse_options(parser)
    begin
      parser.parse!
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      puts e.message
      puts parser
      exit 1
    rescue SystemExit
      # Allow SystemExit to propagate for clean exit
      raise
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
      puts parser
      exit 1
    end
  end
end

scheduler@devxronos:~/Work/Coding/scheduler/lib/import/socsmusic$ cat options.rb
require 'optparse'
require 'optparse/date'

class Options
  attr_reader :event_category_name, :verbose, :start_date, :end_date

  def initialize
    @event_category_name = "Lesson"
    @verbose = false
    @start_date = nil
    @end_date  = nil

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: music_import.rb [options]"

      opts.on("-c", "--category [EVENTCATEGORY]",
              "Specify the name of the event category",
              "to be used for all the fixtures.",
              "Defaults to \"Music\".") do |name|
        @event_category_name = name
      end

      opts.on("-s", "--start_date [DATE]", "Specify the start date (e.g. 2024-09-05)") do |date|
        @start_date = Date.parse(date)
      end

      opts.on("-e", "--end_date [DATE]", "Specify the end date (e.g. 2024-09-06)") do |date|
        @end_date = Date.parse(date)
      end

      opts.on("-v", "--verbose",
              "Run with verbose output") do
        @verbose = true
      end

      opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    parse_options(parser)
  end

  private

  def parse_options(parser)
    begin
      parser.parse!
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      puts e.message
      puts parser
      exit 1
    rescue SystemExit
      # Allow SystemExit to propagate for clean exit
      raise
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
      puts parser
      exit 1
    end
  end
end