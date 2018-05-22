#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#  MsSQL Database => CSV data extractor.
#
#  The idea is that this file contains all the code which does the work,
#  and then platform-specific files include it whilst defining the remainder
#  of the information.
#  

require 'csv'
require 'optparse'
require 'tiny_tds'

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
      @@db_user     = ENV["MSSQL_DB_USER"]
      @@data_server = ENV["MSSQL_DATA_SERVER"]
      @@db_host     = ENV["MSSQL_DB_HOST"]
      @@db_port     = ENV["MSSQL_DB_PORT"]
      @@db_name     = ENV["MSSQL_DB_NAME"]
      unless @@db_user &&
             (@@data_server || (@@db_host && @@db_port)) &&
             @@db_name
        puts "MSSQL_DB_USER must be set." unless @@db_user
        puts "Either MSSQL_DATA_SERVER or MSSQL_DB_HOST and MSSQL_DB_PORT must be set." unless @@data_server || (@@db_host && @@db_port)
        puts "MSSQL_DB_NAME must be set." unless @@db_name
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
    puts "Fetching #{@table_name}"
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
    if ENV["MSSQL_DB_PASSWORD"]
      @@password = ENV["MSSQL_DB_PASSWORD"]
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

  def self.dump_tables(options, tables)

    tables.each do |table|
      table.dump(options.target_dir)
    end
  end

end

class Options

  attr_reader :verbose, :target_dir

  def initialize
    @verbose    = false
    @target_dir = "."
    o = OptionParser.new do |opts|
      opts.banner = "Usage: extractor.rb [options]"

      opts.on("-t", "--target [dirname]", "Specify target directory") do |t|
        @target_dir = t
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @verbose = v
      end

    end
    begin
      o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit 1
    end

  end
end
