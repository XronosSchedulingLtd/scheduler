#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  The purpose of this program is to process dumps of a number of
#  tables from the iSAMS database and turn them into an XML file suitable
#  for importing into Scheduler.
#
#  It replaces the iSAMS Batch API which has become too unreliable to use.
#

require 'csv'
require 'optparse'
require 'ostruct'
require 'nokogiri'
require 'charlock_holmes'

#
#  Not at all happy about this next line, but not sure yet how to
#  structure things better.
#
require_relative '../../lib/import/misimport/slurper'

require_relative 'xmluser'
require_relative 'xmlstaff'
require_relative 'xmlhouse'
require_relative 'xmlpupil'
require_relative 'xmlcustomcategory'
require_relative 'xmlcustomgroup'
require_relative 'xmlcustomgroupmembership'
require_relative 'xmlbuilding'
require_relative 'xmlclassroom'
require_relative 'xmldepartment'
require_relative 'xmlsubject'
require_relative 'xmldslink'

TO_READ = [
  XMLUser,
  XMLStaff,
  XMLHouse,
  XMLPupil,
  XMLCustomCategory,
  XMLCustomGroup,
  XMLCustomGroupMembership,
  XMLBuilding,
  XMLClassroom,
  XMLDepartment,
  XMLSubject,
  XMLDepartmentSubjectLink
]

begin
  options = OpenStruct.new
  options.verbose  = false
  options.data_dir = '.'
  o = OptionParser.new do |opts|
    opts.banner = "Usage: isamsxml.rb [options]"

    opts.on("-d", "--data [DIRECTORY NAME]", "Specify data directory") do |d|
      options.data_dir = d
    end

    opts.on("-h", "--help", "Show this message") do |h|
      puts opts
      exit
    end

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end
  end.parse!

  accumulator = Hash.new
  #
  #  Read in all the CSV files
  #
  TO_READ.each do |current_input|
    unless current_input.construct(accumulator, options.data_dir)
      exit
    end
  end
  #
  #  And now write out our single XML output file.
  #
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.iSAMS do
      xml.EstateManager do
        xml.Buildings do
          XMLBuilding.generate_xml(xml)
        end
      end
      xml.HRManager do
        xml.CurrentStaff do
          XMLStaff.generate_xml(xml)
        end
      end
      xml.SchoolManager do
        XMLHouse.generate_xml(xml)
      end
      xml.TeachingManager do
        xml.Departments do
          XMLDepartment.generate_xml(xml)
        end
      end
      xml.PupilManager do
        xml.CurrentPupils do
          XMLPupil.generate_xml(xml)
        end
        xml.CustomGroupCategory do
          XMLCustomCategory.generate_xml(xml)
        end
        xml.CustomPupilGroupMembershipItems do
          XMLCustomGroupMembership.generate_xml(xml)
        end
        xml.CustomPupilGroups do
          XMLCustomGroup.generate_xml(xml)
        end
      end
    end
  end
  puts builder.to_xml
end

