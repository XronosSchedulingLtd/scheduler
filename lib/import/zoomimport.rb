#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

require 'csv'
require_relative 'common/csvimport'

class ZoomStaffRecord
  REQUIRED_COLUMNS = [
    CSVColumn["Email",      :email,      :string],
    CSVColumn["First Name", :first_name, :string],
    CSVColumn["Last Name",  :last_name,  :string],
    CSVColumn["User Group", :user_group, :string],
    CSVColumn["PMI",        :zoom_id,    :string]
  ]

  include CSVImport

  def wanted?
    self.user_group == "Staff" || self.user_group == "Senior Teaching"
  end

  def adjust(accumulator)
    self.zoom_id.gsub!(/[- ]/, '')
  end

  def self.construct(file_name)
    records, message = self.slurp(file_name)
    unless records
      puts message
      exit
    end
    records
  end

  #
  #  And begin
  #
  if ARGV.length == 1
    records = ZoomStaffRecord.construct(ARGV[0])
    num_updated = 0
    records.each do |record|
      if staff = Staff.find_by(email: record.email)
        if staff.zoom_id != record.zoom_id
          puts "Updating #{record.first_name} #{record.last_name}"
          staff.zoom_id = record.zoom_id
          staff.save!
          num_updated += 1
        end
      end
    end
    puts "#{num_updated} staff records updated"
  else
    puts "Usage: zoomimport.rb <name of CSV file>"
  end


end
