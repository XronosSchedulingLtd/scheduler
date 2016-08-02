#!/usr/bin/env ruby
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

  def initialize(table_name, fields)
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

  def dump
    get_password unless @@password
    csv = CSV.open(@table_name + ".csv", "wb")
    client = TinyTds::Client.new(
      username: "AbingdonAccess",
      password: @@password,
      dataserver: "isams",
      database: "iSAMS_Abingdon")
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
    if ENV["PASSWORD"]
      @@password = ENV["PASSWORD"]
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
    DatabaseTable.new("tblactivitymanageractivitycategory", :all),
    DatabaseTable.new("TblActivityManagerActivityCategoryTypeLink", :all),
    DatabaseTable.new("TblActivityManagerActivity", :all),
    DatabaseTable.new("TblActivityManagerActivityGroup", :all),
    DatabaseTable.new("TblActivityManagerActivityGroupPupilLink", :all),
    DatabaseTable.new("TblActivityManagerActivityGroupTeacherLink", :all),
    DatabaseTable.new("TblActivityManagerActivityManager", :all),
    DatabaseTable.new("TblActivityManagerActivitySecurityType", :all),
    DatabaseTable.new("TblActivityManagerActivitySecurityUser", :all),
    DatabaseTable.new("TblActivityManagerActivitySecurityUserGroup", :all),
    DatabaseTable.new("TblActivityManagerActivityStatus", :all),
    DatabaseTable.new("TblActivityManagerActivityTerminologyLink", :all),
    DatabaseTable.new("TblActivityManagerActivityType", :all),
    DatabaseTable.new("TblActivityManagerActivityTypeGroupLink", :all),
    DatabaseTable.new("TblActivityManagerAudit", :all),
    DatabaseTable.new("TblActivityManagerEvent", :all),
    DatabaseTable.new("TblActivityManagerEventOccurrence", :all),
    DatabaseTable.new("TblActivityManagerEventPupilLink", :all),
    DatabaseTable.new("TblActivityManagerEvents", :all),
    DatabaseTable.new("TblActivityManagerEventsGroup", :all),
    DatabaseTable.new("TblActivityManagerEventsGroupLink", :all),
    DatabaseTable.new("TblActivityManagerEventsPupilLink", :all),
    DatabaseTable.new("TblActivityManagerEventsRecurrence", :all),
    DatabaseTable.new("TblActivityManagerEventsSection", :all),
    DatabaseTable.new("TblActivityManagerEventsSubGroup", :all),
    DatabaseTable.new("TblActivityManagerEventsTeacherLink", :all),
    DatabaseTable.new("TblActivityManagerEventTeacherLink", :all),
    DatabaseTable.new("TblActivityManagerExportCustomField", :all),
    DatabaseTable.new("TblActivityManagerExportField", :all),
    DatabaseTable.new("TblActivityManagerFolder", :all),
    DatabaseTable.new("TblActivityManagerGlobalFeature", :all),
    DatabaseTable.new("TblActivityManagerGlobalFeatureOverride", :all),
    DatabaseTable.new("TblActivityManagerGlobalFeatureSetting", :all),
    DatabaseTable.new("TblActivityManagerGlobalSubFeature", :all),
    DatabaseTable.new("TblActivityManagerGlobalSubFeatureOverride", :all),
    DatabaseTable.new("TblActivityManagerGroup", :all),
    DatabaseTable.new("TblActivityManagerGroupPupilLink", :all),
    DatabaseTable.new("TblActivityManagerGroupSubGroupLink", :all),
    DatabaseTable.new("TblActivityManagerGroupTeacherLink", :all),
    DatabaseTable.new("TblActivityManagerRegistrationCode", :all),
    DatabaseTable.new("TblActivityManagerRegistrationPupils", :all),
    DatabaseTable.new("TblActivityManagerTerminology", :all),
    DatabaseTable.new("TblActivityManagerTimetablePreferences", :all),
    DatabaseTable.new("TblActivityManagerUserSetting", :all)
  ]

  def self.dump_tables
    #
    #  Require tiny_tds only if we are actually doing a data dump.
    #  This is because it has dependencies which might not be available
    #  on a development system.
    #
    require 'tiny_tds'

    TABLES.each do |table|
      table.dump
    end
  end

end

begin
  options = OpenStruct.new
  options.verbose           = false
  options.do_extract        = false
  o = OptionParser.new do |opts|
    opts.banner = "Usage: extractor.rb [options]"

    opts.on("-e", "--extract", "Extract data from iSAMS to CSV files") do |e|
      options.do_extract = e
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
    DatabaseTable.dump_tables
  end

end
