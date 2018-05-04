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

tables = [
  DatabaseTable.new("CH_AC_SUBJECT_SETS", :all),
  DatabaseTable.new("CH_AC_TIMETABLE",    :all)
]
options = Options.new

DatabaseTable.dump_tables(options, tables)
