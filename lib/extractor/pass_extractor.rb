#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#  MsSQL Database => CSV data extractor.
#  

require 'csv'
require 'optparse'

require_relative 'extractor'

DB_TABLE_PREFIX = ENV["DB_TABLE_PREFIX"]
if DB_TABLE_PREFIX.nil?
  puts "DB_TABLE_PREFIX needs to be defined in ~/etc/whichsystem."
end

tables = [
  DatabaseTable.new("#{DB_TABLE_PREFIX}_AC_NEEDING_COVER",      :all),
  DatabaseTable.new("#{DB_TABLE_PREFIX}_AC_PROVIDING_COVER",    :all),
  DatabaseTable.new("#{DB_TABLE_PREFIX}_AC_SUBJECT_SETS",       :all),
  DatabaseTable.new("#{DB_TABLE_PREFIX}_AC_TIMETABLE",          :all),
  DatabaseTable.new("#{DB_TABLE_PREFIX}_AD_CURR_SUBJECTS",      :all),
  DatabaseTable.new("#{DB_TABLE_PREFIX}_AD_CURR_BASIC_DETAILS", :all),
  DatabaseTable.new("#{DB_TABLE_PREFIX}_ST_DETAILS",
                     %w(
                       STAFF_ID
                       CODE
                       LEAVE_DATE
                       SHORT_NAME
                       NAME_ID
                       NAME_CODE
                       NAME
                       SURNAME
                       FIRST_NAMES
                       PREFERRED_NAME
                       TITLE
                       INITIALS
                       INTERNAL_EMAIL_ADDRESS
                       TIMETABLE_CODE
                     )
                   )
]
options = Options.new

DatabaseTable.dump_tables(options, tables)
