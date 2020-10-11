#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
# A script to turn the full fortnight's timetable into a CSV thingy.
#

require 'csv'
require 'spreadsheet'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

require_relative 'filing'

class Options

  attr_reader :staff_group_name,
              :template_name,
              :output_name,
              :user_id

  def initialize
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: timetabletoxls.rb [options]"

      opts.on("-h", "--help",
              "Print this help and exit.") do |h|
        STDERR.puts opts
        exit
      end

      opts.on("-t", "--template TEMPLATE", String,
              "Specify which template (day shape) to use.") do |t|
        @template_name = t
      end

      opts.on("-g", "--group GROUP", String,
              "Specify which group of staff to check for.") do |g|
        @staff_group_name = g
      end

      opts.on("-o", "--output FILENAME", String,
              "Specify the name of the file to which to",
              "send output.  Without this, output is",
              "written to stdout.") do |o|
        @output_name = o
      end

      opts.on("-u", "--user USERID", String,
              "The id of a user to whom to give the",
              "output file.  If no file name is given",
              "then this has no effect.") do |u|
        @user_id = u
      end

    end
    begin
      parser.parse!
      unless @template_name
        raise OptionParser::MissingArgument.new("Must specify a template")
      end
      unless @staff_group_name
        raise OptionParser::MissingArgument.new("Must specify a group of staff")
      end
    rescue Exception => e
      unless e.class == SystemExit
        STDERR.puts
        STDERR.puts e
        STDERR.puts
        STDERR.puts parser
      end
      exit
    end

  end
end

options = Options.new
start_date = Setting.tt_store_start
num_weeks  = Setting.tt_cycle_weeks

rota_template = RotaTemplate.find_by(name: options.template_name)

unless rota_template
  STDERR.puts "Rota template \"#{options.template_name}\" not found."
  exit
end

group = Group.find_by(name: options.staff_group_name)

unless rota_template
  STDERR.puts "Staff group \"#{options.staff_group_name}\" not found."
  exit
end

all_staff = group.members(nil, true, true).sort

if options.output_name
  if options.user_id
    user = User.find_by(id: options.user_id)
    if user
      begin
        output = UserFiling.new(user, options.output_name, "ASCII-8BIT")
      rescue Exception => e
        STDERR.puts "Failed to open UserFile \"#{options.output_name}\" for user #{options.user_id} - #{user.name}"
        STDERR.puts e
        exit
      end
    else
      STDERR.puts "User with id #{options.user_id} not found."
      exit
    end
  else
    begin
      output = File.open(options.output_name, "w:ASCII-8BIT")
    rescue Exception => e
      STDERR.puts "Can't open \"#{options.output_name}\""
      STDERR.puts e
      exit
    end
  end
else
  STDERR.puts "An output file name must be specified."
  exit
end

#
#  How many periods do we have?
#

max_periods = 0
active_days = []
7.times do |i|
  num_periods = rota_template.slots_for(start_date + i.days).count
  active_days[i] = (num_periods > 0)
  if num_periods > max_periods
    max_periods = num_periods
  end
end

#puts "We have #{max_periods} periods per day"

book = Spreadsheet::Workbook.new

num_weeks.times do |week_no|
  week_letter = week_no == 0 ? "A" : "B"
  sheet = book.create_worksheet(name: "Week #{week_letter}")
  sheet.row(0).concat(["", "", "Staff timetables week #{week_letter}"])
  sheet.row(1).concat(["", ""])
  sheet.row(2).concat(["", ""])
  7.times do |i|
    if active_days[i]
      max_periods.times do |j|
        if j == 0
          sheet.row(1) << (start_date + i.days).strftime("%A")
        else
          sheet.row(1) << ""
        end
        sheet.row(2) << "P#{j}"
      end
    end
  end
  all_staff.each_with_index do |staff, i|
    row = sheet.row(3 + i)
    row.concat([staff.name, staff.initials])
    #
    #  And now work out all the timetable entries for this member of
    #  staff.
    #
    7.times do |j|
      if active_days[j]
        #
        #  If a day is active, then we must put something in a cell,
        #  even if it's a blank.
        #
        #  Currently hitting the d/b once for each slot.  This could
        #  be done more efficiently, at the expense of doing more work
        #  here.
        #
        #  Could fetch a whole day in one go, then sort them ourselves.
        #
        #  Could fetch a whole week in one go, then ditto.
        #
        date = start_date + ((week_no * 7) + j).days
        slots = rota_template.slots_for(date).sort
        slots.each do |slot|
          slot_starts_at = Time.zone.parse(slot.starts_at, date)
          slot_ends_at = Time.zone.parse(slot.ends_at, date)
          found =
            staff.commitments_during(start_time: slot_starts_at,
                                     end_time: slot_ends_at,
                                     and_by_group: false).
                  includes(:event)
          if found.size > 0
            row << found.collect {|f| f.event.body}.join("\n")
          else
            #
            #  An empty cell
            #
            row << ""
          end
        end
      end
    end
  end
  sheet.column(0).width = 30
end

#book.write("timetable1.xls")

#File.open("timetable2.xls", "a+b:ASCII-8BIT") do |file|
#  book.write(file)
#end

buffer = StringIO.new
book.write(buffer)

buffer.rewind

output.write(buffer.read)
output.close
