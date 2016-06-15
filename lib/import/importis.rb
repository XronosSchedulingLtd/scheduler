#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# Portions Copyright (C) 2014 Abingdon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'optparse'
require 'optparse/date'
require 'ostruct'
require 'yaml'
require 'nokogiri'
#require 'ruby-prof'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

#
#  A script to load in the XML file which exports from iSAMS.
#

IMPORT_DIR = 'import'

IsamsField = Struct.new(:selector, :attr_name, :target_type)

module Creator
  def self.included(parent)
    parent.extend ClassMethods
    parent::REQUIRED_FIELDS.each do |field|
      attr_accessor field[:attr_name]
    end
  end

  #
  #  I could just call this function initialize, but give it a slightly
  #  different name so that the includer can add more processing before or
  #  after our work.
  #
  def do_initialize(entry)
    self.class::REQUIRED_FIELDS.each do |field|
      attr_name = field[:attr_name]
      if field[:selector] == "Id"
        #
        #  Special case.  This one comes through as an attribute and
        #  is always numeric.
        #
        self.send("#{attr_name}=", entry.attribute("Id").value.to_i)
      else
        contents = entry.at_css(field[:selector])
        if contents
          if field[:target_type] == :string
            self.send("#{attr_name}=", contents.text)
          else
            self.send("#{attr_name}=", contents.text.to_i)
          end
        else
          #
          #  For ease of processing, missing strings are taken as
          #  empty strings, but missing values are set as nil.
          #
          if field[:target_type] == :string
            self.send("#{attr_name}=", "")
          else
            self.send("#{attr_name}=", nil)
          end
        end
      end
    end
  end

  module ClassMethods
    def slurp(data)
      results = Array.new
      entries = data.css(self::SELECTOR)
      if entries && entries.size > 0
        entries.each do |entry|
          results << self.new(entry)
        end
      else
        puts "Unable to find entries using selector \"#{self::SELECTOR}\"."
      end
      results
    end
  end
end

class IS_Loader
  class IS_Staff
    SELECTOR = "HRManager CurrentStaff StaffMember"
    REQUIRED_FIELDS = [
      IsamsField["Id",                 :isams_id, :integer],
      IsamsField["PreviousMISId",      :sb_id,    :integer],
      IsamsField["Initials",           :initials, :string],
      IsamsField["Title",              :title,    :string],
      IsamsField["Forename",           :forename, :string],
      IsamsField["Surname",            :surname,  :string],
      IsamsField["SchoolEmailAddress", :email,    :string]
    ]

    include Creator

    def initialize(entry)
      do_initialize(entry)
    end

  end

  class IS_Pupil
    SELECTOR = "PupilManager CurrentPupils Pupil"
    REQUIRED_FIELDS = [
      IsamsField["Id",                 :isams_id, :integer],
      IsamsField["SchoolCode",         :sb_id,    :integer],
      IsamsField["Initials",           :initials, :string],
      IsamsField["Title",              :title,    :string],
      IsamsField["Forename",           :forename, :string],
      IsamsField["Surname",            :surname,  :string],
      IsamsField["EmailAddress",       :email,    :string]
    ]

    include Creator

    def initialize(entry)
      do_initialize(entry)
    end

  end

  def read_isams_data
    data = Nokogiri::XML(File.open(Rails.root.join(IMPORT_DIR, "data.xml")))
    staff =  IS_Staff.slurp(data)
    puts "Got #{staff.count} staff."
    puts staff[0].inspect
    pupils = IS_Pupil.slurp(data)
    puts "Got #{pupils.count} pupils."
    puts pupils[0].inspect
  end
end

loader = IS_Loader.new
loader.read_isams_data

