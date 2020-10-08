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

#
#  Hard-coded simple version to test the concept.
#

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

def initials_from(elements)
  elements.map(&:initials).sort.join(",")
end

PER_LINE = 15
#
#  Specific for my purposes, puts up to N sets of initials on a line, 
#  then starts a new line with a fixed indent.
#
def splat_initials(elements)
  #
  #  Don't want to modify the caller's copy.
  #
  working = elements.map(&:initials).sort
  batch = working.shift(PER_LINE)
  puts batch.join(",")
  while working.size > 0
    batch = working.shift(PER_LINE)
    puts "               #{batch.join(",")}"
  end
end


start_date = Setting.tt_store_start
num_weeks  = Setting.tt_cycle_weeks

rota_template = RotaTemplate.find_by(name: "Duty slots")
group = Group.find_by(name: "Duty staff")

everyone = group.members(nil, true, true)
puts "Eligible for duty:"
print "               "
splat_initials(everyone)

puts ""

week_summaries = []

num_weeks.times do |i|
  current_week = WeekSummary.new(i == 0 ? "A" : "B")
  puts "=================================================="
  puts " Week #{current_week.week_letter}"
  puts "=================================================="
  7.times do |j|
    date = start_date + (7 * i).days + j.days
    day_name = date.strftime("%A")
    current_day = DaySummary.new(day_name)
    todays_slots = rota_template.slots_for(date)
    puts ""
    puts "Checking #{day_name}"

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

      if i == 0
        #
        #  First slot is whole day.  Anyone free for the whole day
        #  should be ignored.
        #
        free_all_day = ff.free_elements
        if free_all_day.size > 0
          puts "Free all day: #{initials_from(free_all_day)}"
          current_day.free_all_day = free_all_day
          puts ""
        end
      else
        print "#{slot.starts_at} - #{slot.ends_at}: "

        if ff.free_elements.count == ff.member_elements.count
          puts "Everyone"
        elsif ff.free_elements.count > ff.member_elements.count - 10
          puts "All but: #{initials_from(ff.member_elements - ff.free_elements)}"
        else
          free_elements = ff.free_elements - free_all_day
          splat_initials(free_elements)
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
    current_week << current_day
  end
  puts ""
  week_summaries << current_week
end

if week_summaries.size > 1
  puts "=================================================="
  puts " Both Weeks"
  puts "=================================================="
  #
  #  Note that we assume that we have built the weeks correctly, with 7
  #  days in each week and the same number of slots on matching days.  If
  #  we haven't then there's something wrong with the earlier code.
  #
  week_summaries[0].zip(week_summaries[1]).each do |weeka_day, weekb_day|
    puts ""
    puts "Checking #{weeka_day.day_name}"
    free_all_day =
      weeka_day.free_all_day & weekb_day.free_all_day
    if free_all_day.size > 0
      puts "Free all day: #{initials_from(free_all_day)}"
      puts ""
    end
    weeka_day.zip(weekb_day).each do |slota, slotb|
      free_elements = slota.free_elements & slotb.free_elements
      print "#{slota.starts_at} - #{slota.ends_at}: "

      if free_elements.count == everyone.count
        puts "Everyone"
      elsif free_elements.count > everyone.count - 10
        puts "All but: #{initials_from(everyone - free_elements)}"
      else
        effectively_free = free_elements - free_all_day
        splat_initials(effectively_free)
      end
    end


  end
end

#
#  Let's print a handy lookup table
#

def pad_to(initials, desired_size)
  "#{initials}       "[0,desired_size]
end

max_initials = everyone.map(&:initials).collect {|i| i.length}.max

everyone.sort_by {|e| e.initials}.each do |e|
  puts "#{pad_to(e.initials, max_initials)} : #{e.name}"
end

