require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: importsb.rb [options]"

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

end.parse!


puts options
puts ARGV

