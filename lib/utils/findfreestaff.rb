#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
# A script to find free staff for a specified list of periods throughout
# the timetable cycle.
#

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

require_relative 'filing'

def pad_to(text, desired_size)
  "#{text}       "[0,desired_size]
end

class Options

  attr_reader :all_day,
              :both_weeks,
              :template_name,
              :staff_group_name,
              :list_staff,
              :output_name,
              :reverse_output,
              :user_id

  def initialize
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: findfreestaff.rb [options]"

      opts.on("-h", "--help",
              "Print this help and exit.") do |h|
        STDERR.puts opts
        exit
      end

      opts.on("-a", "--all-day",
              "Take the first slot as specifying an",
              "all-day period and identify those staff",
              "who are free throughout.") do |a|
        @all_day = a
      end

      opts.on("-b", "--both-weeks",
              "As well as evaluating each week separately",
              "do a run for both weeks together.  Only",
              "those free for both weeks in any indicated",
              "period are then listed") do |b|
        @both_weeks = b
      end

      opts.on("-t", "--template TEMPLATE", String,
              "Specify which template (day shape) to use.") do |t|
        @template_name = t
      end

      opts.on("-g", "--group GROUP", String,
              "Specify which group of staff to check for.") do |g|
        @staff_group_name = g
      end

      opts.on("-l", "--list",
              "Print a list of staff considered, with",
              "their initials.") do |l|
        @list_staff = l
      end

      opts.on("-o", "--output FILENAME", String,
              "Specify the name of the file to which to",
              "send output.  Without this, output is",
              "written to stdout.") do |o|
        @output_name = o
      end

      opts.on("-r", "--reverse",
              "Also produce output in reverse, listing",
              "free periods for each staff member, rather",
              "than the usual list of staff for each",
              "period.") do |r|
        @reverse_output = r
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

class WeekSummary < Array
  attr_reader :week_letter

  def initialize(week_letter)
    @week_letter = week_letter
  end
end

class DaySummary < Array
  attr_reader :day_name, :free_all_day

  def initialize(day_name)
    @day_name = day_name
    @free_all_day = []
  end

  def free_all_day=(list)
    @free_all_day = list
  end

end

class SlotSummary

  attr_reader :starts_at, :ends_at, :free_elements

  def initialize(starts_at, ends_at, free_elements)
    @starts_at     = starts_at
    @ends_at       = ends_at
    @free_elements = free_elements
  end

end

class StaffSlotList
  attr_reader :slot_count, :initials, :name

  def initialize(initials, name)
    @initials = initials
    @name     = name
    @slot_count = 0
    @weeks = Hash.new
  end

  def record_slot(week_letter, day_name, timing)
    @slot_count += 1
    week = (@weeks[week_letter] ||= Hash.new)
    day = (week[day_name] ||= Array.new)
    day << timing
  end

  def each
    ["A", "B", "Both"].each do |week_letter|
      week = @weeks[week_letter]
      if week
        if week_letter == "Both"
          yield "Both weeks"
        else
          yield " Week #{week_letter}"
        end
        %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday).each do |day_name|
          day = week[day_name]
          if day
            yield "  #{pad_to(day_name, 10)} #{day.join(", ")}"
#            yield "  #{day_name}"
#            yield "   #{day.join(", ")}"
          end
        end
      end
    end
  end
end

def initials_from(elements)
  elements.map(&:initials).sort.join(",")
end

PER_LINE = 15
#
#  Specific for my purposes, output.puts up to N sets of initials on a line, 
#  then starts a new line with a fixed indent.
#
def splat_initials(output, elements)
  #
  #  Don't want to modify the caller's copy.
  #
  working = elements.map(&:initials).sort
  batch = working.shift(PER_LINE)
  output.puts batch.join(",")
  while working.size > 0
    batch = working.shift(PER_LINE)
    output.puts "               #{batch.join(",")}"
  end
end



#
#=======================================================================
#
#   Start of main code
#
#=======================================================================
#

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

everyone = group.members(nil, true, true)
every_element = everyone.collect {|s| s.element}

staff_hash = Hash.new
everyone.each do |s|
  staff_hash[s.initials] = StaffSlotList.new(s.initials, s.name)
end

if options.output_name
  if options.user_id
    user = User.find_by(id: options.user_id)
    if user
      begin
        output = UserFiling.new(user, options.output_name)
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
      output = File.open(options.output_name, "w")
    rescue Exception => e
      STDERR.puts "Can't open \"#{options.output_name}\""
      STDERR.puts e
      exit
    end
  end
else
  output = STDOUT
end

#
#  And now start processing.
#

output.puts "Eligible:"
output.print "               "
splat_initials(output, everyone)

output.puts ""

week_summaries = []

num_weeks.times do |i|
  current_week = WeekSummary.new(i == 0 ? "A" : "B")
  output.puts "=================================================="
  output.puts " Week #{current_week.week_letter}"
  output.puts "=================================================="
  7.times do |j|
    date = start_date + (7 * i).days + j.days
    day_name = date.strftime("%A")
    current_day = DaySummary.new(day_name)
    todays_slots = rota_template.slots_for(date)
    if todays_slots.size > 0
      output.puts ""
      output.puts "Checking #{day_name}"

      free_all_day = []

      todays_slots.sort.each_with_index do |slot, i|

        ff = Freefinder.new({
          element: group.element,
          on: date,
          memberships_on: Date.today,
          start_time_text: slot.starts_at,
          end_time_text: slot.ends_at
        })
        ff.do_find

        if options.all_day && (i == 0)
          #
          #  First slot is whole day.  Anyone free for the whole day
          #  should be ignored.
          #
          free_all_day = ff.free_elements
          if free_all_day.size > 0
            output.puts "Free all day: #{initials_from(free_all_day)}"
            current_day.free_all_day = free_all_day
            output.puts ""
          end
        else
          timing = "#{slot.starts_at} - #{slot.ends_at}"
          output.print "#{timing}: "

          free_elements = ff.free_elements - free_all_day
          if ff.free_elements.count == ff.member_elements.count
            output.puts "Everyone"
          elsif ff.free_elements.count > ff.member_elements.count - 10
            output.puts "All but: #{initials_from(ff.member_elements - ff.free_elements)}"
          else
            splat_initials(output, free_elements)
          end
          free_elements.each do |e|
            staff_hash[e.initials].record_slot(current_week.week_letter,
                                               day_name,
                                               timing)
          end
          #
          #  Note that we record the raw list of free elements, not the one
          #  where we have subtracted the free-all-day elements.  This is
          #  because when we do the calculation for both weeks together
          #  the free-all-day list may be different.
          #
          current_day <<
            SlotSummary.new(slot.starts_at, slot.ends_at, ff.free_elements)
        end
      end
    end
    current_week << current_day
  end
  output.puts ""
  week_summaries << current_week
end

if options.both_weeks && (week_summaries.size > 1)
  output.puts "=================================================="
  output.puts " Both Weeks"
  output.puts "=================================================="
  #
  #  Note that we assume that we have built the weeks correctly, with 7
  #  days in each week and the same number of slots on matching days.  If
  #  we haven't then there's something wrong with the earlier code.
  #
  week_summaries[0].zip(week_summaries[1]).each do |weeka_day, weekb_day|
    if weeka_day.size > 0
      output.puts ""
      output.puts "Checking #{weeka_day.day_name}"
      free_all_day =
        weeka_day.free_all_day & weekb_day.free_all_day
      if free_all_day.size > 0
        output.puts "Free all day: #{initials_from(free_all_day)}"
        output.puts ""
      end
      weeka_day.zip(weekb_day).each do |slota, slotb|
        free_elements = slota.free_elements & slotb.free_elements
        timing = "#{slota.starts_at} - #{slota.ends_at}"
        output.print "#{timing}: "

        if free_elements.count == every_element.count
          output.puts "Everyone"
        elsif free_elements.count > every_element.count - 10
          output.puts "All but: #{initials_from(every_element - free_elements)}"
        else
          effectively_free = free_elements - free_all_day
          splat_initials(output, effectively_free)
        end
        free_elements.each do |e|
          staff_hash[e.initials].record_slot("Both",
                                             weeka_day.day_name,
                                             timing)
        end
      end
    end
  end
end

max_initials = everyone.map(&:initials).collect {|i| i.length}.max

if options.reverse_output
  output.puts
  output.puts "By staff member:"
  staff_hash.keys.sort.each do |key|
    output.puts
    entry = staff_hash[key]
    output.puts "#{pad_to(entry.initials, max_initials)} : #{entry.name}"
    entry.each do |string|
      output.puts string
    end
  end
  output.puts
end

#
#  Let's print a handy lookup table
#

if options.list_staff


  everyone.sort_by {|e| e.initials}.each do |e|
    output.puts "#{pad_to(e.initials, max_initials)} : #{e.name}"
  end
end

unless output == STDOUT
  output.close
end

