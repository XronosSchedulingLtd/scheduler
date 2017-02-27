#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'date'

def date_of_sunday
  #
  #  First we want the date of the Sunday of the current week.
  #
  today = Date.today
  today - today.wday
end

puts date_of_sunday.strftime("%Y-%m-%d")
