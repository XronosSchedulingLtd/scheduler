#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#  iSAMS => CSV data extractor.
#  
#  This program exists extract some information from iSAMS in the form
#  of CSV files.  Where possible we use the iSAMS API, but it isn't
#  very complete yet and this program fetches the rest of the
#  necessary data.
#

require 'tempfile'
require 'csv'
require 'optparse'
require 'ostruct'
require 'charlock_holmes'
require 'time'
require 'pathname'

class DatabaseTable
  @@password = nil
  @@db_user = nil

  #
  #  This utility currently expects all its parameters to be given
  #  in the environment.  Thus they can be set in a single file outside
  #  the Scheduler source tree, rather than having to be embedded in
  #  scripts.
  #
  #  If there aren't enough params set, it will simply abort.
  #
  #  Password is handled separately.  If it hasn't been set then
  #  we prompt for it.
  #
  def self.get_params_from_env
    #
    #  We will do this only once.
    #
    unless @@db_user
      #
      #  It's annoying to get an error message about one problem,
      #  only to fix that and then get another message about another
      #  problem.  Try to identify all the problems in one go,
      #  and then report them.
      #
      @@db_user     = ENV["ISAMS_DB_USER"]
      @@data_server = ENV["ISAMS_DATA_SERVER"]
      @@db_host     = ENV["ISAMS_DB_HOST"]
      @@db_port     = ENV["ISAMS_DB_PORT"]
      @@db_name     = ENV["ISAMS_DB_NAME"]
      unless @@db_user &&
             (@@data_server || (@@db_host && @@db_port)) &&
             @@db_name
        puts "ISAMS_DB_USER must be set." unless @@db_user
        puts "Either ISAMS_DATA_SERVER or ISAMS_DB_HOST and ISAMS_DB_PORT must be set." unless @@data_server || (@@db_host && @@db_port)
        puts "ISAMS_DB_NAME must be set." unless @@db_name
        abort("Please check your ~/etc/isauth file.")
      end
    end
  end

  def initialize(table_name, fields)
    self.class.get_params_from_env
    @table_name = table_name
    @fields = []
    if fields == :all
      @get_all = true
    else
      @get_all = false
      if fields.is_a?(String)
        @fields << fields
      elsif fields.is_a?(Array)
        fields.each do |field|
          @fields << field
        end
      else
        raise "Can't cope with \"fields\" as a #{fields.class}"
      end
    end
  end

  def columns
    if @get_all
      "*"
    else
      @fields.collect {|f| f.to_s}.join(",")
    end
  end

  def dump(target_dir)
    get_password unless @@password
    csv = CSV.open(File.join(target_dir, @table_name + ".csv"), "wb")
    if @@data_server
      client = TinyTds::Client.new(
        username: @@db_user,
        password: @@password,
        dataserver: @@data_server,
        database: @@db_name)
    else
      client = TinyTds::Client.new(
        username: @@db_user,
        password: @@password,
        host: @@db_host,
        port: @@db_port.to_i,
        database: @@db_name)
    end
    result = client.execute("SELECT #{columns} FROM #{@table_name};")
    fields = result.fields
    csv << fields
    result.each do |row|
      csv << fields.collect {|f| row[f]}
    end
    client.close
    csv.close
  end

  def get_password
    if ENV["ISAMS_DB_PASSWORD"]
      @@password = ENV["ISAMS_DB_PASSWORD"]
    else
      begin
        print 'Password: '
        # We hide the entered characters before to ask for the password
        system 'stty -echo'
        @@password = $stdin.gets.chomp
        system 'stty echo'
      rescue NoMethodError, Interrupt
        # When the process is exited, we display the characters again
        # And we exit
        system 'stty echo'
        exit
      end
      puts ""
    end
  end

  TABLES = [
    DatabaseTable.new("TblActivityManagerEvent", :all),
    DatabaseTable.new("TblActivityManagerEventOccurrence", :all),
    DatabaseTable.new("TblActivityManagerEventPupilLink", :all),
    DatabaseTable.new("TblActivityManagerEventTeacherLink", :all),
    DatabaseTable.new("TblActivityManagerGroup", :all),
    DatabaseTable.new("TblActivityManagerGroupPupilLink", :all),
    DatabaseTable.new("TblCoverManagerCover", :all)
  ]

  def self.dump_tables(target_dir)
    #
    #  Require tiny_tds only if we are actually doing a data dump.
    #  This is because it has dependencies which might not be available
    #  on a development system.
    #
    require 'tiny_tds'

    TABLES.each do |table|
      table.dump(target_dir)
    end
  end

end

begin
  options = OpenStruct.new
  options.verbose           = false
  options.do_extract        = false
  options.target_dir        = "."
  o = OptionParser.new do |opts|
    opts.banner = "Usage: extractor.rb [options]"

    opts.on("-e", "--extract", "Extract data from iSAMS to CSV files") do |e|
      options.do_extract = e
    end

    opts.on("-t", "--target [dirname]", "Specify target directory") do |t|
      options.target_dir = t
    end

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end

  end
  begin
    o.parse!
  rescue OptionParser::InvalidOption => e
    puts e
    puts o
    exit 1
  end

  if options.do_extract
    DatabaseTable.dump_tables(options.target_dir)
  end

end
