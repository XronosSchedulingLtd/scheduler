#!/usr/bin/env ruby
#
# XMLCAT - a small utility
# Copyright (C) 2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  This utility exists to overcome a bug in the iSAMS data extraction API,
#  although it may have other uses as well.
#
#  For some odd reason, the iSAMS API runs ridiculously slowly - extractions
#  which one would expect to take milli-seconds take instead tens of seconds.
#  After 35 seconds it times itself out and returns an error instead of
#  the requested data.
#
#  A suggested workaround is to split requests up into several parts,
#  resulting in several XML files instead of just one.
#
#  This utility does the job of glueing them back together again.
#
#

require 'optparse'
require 'nokogiri'

class Options

  attr_reader :verbose,
              :min_size,
              :error_element,
              :nest_at

  def initialize
    @verbose       = false
    @min_size      = 0
    @error_element = nil
    @nest_at       = nil

    OptionParser.new do |opts|
      opts.banner = "Usage: xmlcat [options] <filename> [<filename>...]"

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @verbose = v
      end

      opts.on("-m", "--min_size SIZE", Integer,
              "Specify a minimum size of input file.",
              "Anything smaller will cause the utility",
              "to exit with an error status.") do |m|
        @min_size = m
      end

      opts.on("-e", "--error_element XPATH",
              "Specify an error element in the input",
              "files.  Presence of this element will",
              "be taken as indicating an error and",
              "will stop processing.") do |e|
        @error_element = e
      end

      opts.on("-n", "--nest_at XPATH",
              "Specify the element at which to begin the",
              "nesting process.  Each file will be",
              "expected to have an element which matches",
              "the given XPATH. The output file will",
              "contain a single instance of this XPATH",
              "containing the corresponding contents from",
              "all the input files.") do |n|
        @nest_at = n
      end

    end.parse!
  end
end

options = Options.new

if ARGV.size > 0
  data_sets = Array.new
  unless options.nest_at
    STDERR.puts "The --nest_at option must be specified."
    exit 4
  end
  ARGV.each do |file_name|
    if options.min_size > 0
      if File.size(file_name) < options.min_size
        exit 2
      end
    end
    data_sets << Nokogiri::XML(File.open(file_name))
  end
  if options.error_element
    #
    #  Check for forbidden contents (indicating an error in data
    #  extraction).
    #
    data_sets.each_with_index do |ds, i|
      ds.xpath("#{options.error_element}").each do |baddie|
        STDERR.puts "File #{ARGV[i]} contains node #{options.error_element}"
        STDERR.puts "Aborting"
        exit 3
      end
    end
  end
  #
  #  So, lets try to merge them.  Use the first one (which is now in
  #  memory) to merge the others into.
  #
  first_set = data_sets.pop
  first_name = ARGV.pop
  merge_into = first_set.xpath(options.nest_at)
  unless merge_into.size == 1
    if merge_into.size == 0
      STDERR.puts "XPATH #{options.nest_at} not found in file #{first_name}."
    else
      STDERR.puts "Found #{merge_into.size} instances of #{options.nest} in file #{first_name}."
    end
    exit 5
  end
  merge_node = merge_into[0]
  data_sets.each_with_index do |ds, i|
    to_merge = ds.xpath(options.nest_at)
    unless to_merge.size == 1
      if to_merge.size == 0
        STDERR.puts "XPATH #{options.nest_at} not found in file #{ARGV[i]}."
      else
        STDERR.puts "Found #{to_merge.size} instances of #{options.nest} in file #{ARGV[i]}."
      end
      exit 6
    end
    to_merge.children.each do |child|
      merge_node.add_child(child)
    end
  end
  #
  #  And write it out.
  #
  puts first_set.to_xml
else
  STDERR.puts "You must specify at least one file argument."
  exit 1
end
