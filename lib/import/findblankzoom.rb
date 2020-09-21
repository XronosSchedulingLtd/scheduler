#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#  This script finds and lists all the staff who seem to have current
#  lessons (i.e. entries in the timetable) but who don't have a Zoom
#  id recorded.
#
#  It's horribly inefficient but it does the job.
#

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

eventcategory = Eventcategory.find_by(name: "Lesson")
start_date = Setting.first.tt_store_start

puts eventcategory.name
puts start_date

events = eventcategory.events.beginning(start_date).until(start_date + 14.days)

puts events.count

staff = events.collect {|e| e.staff}.flatten.uniq

puts staff.count

staff.each do |s|
  if s.zoom_id.blank?
    puts s.name
  end
end
