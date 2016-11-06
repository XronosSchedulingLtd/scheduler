#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'optparse'
require 'optparse/date'
require 'ostruct'
require 'date'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

require_relative 'options'

class ClashChecker
  def initialize(options)
    @options    = options
    @start_date = options.start_date
    if options.end_date
      @end_date = options.end_date
    else
      #
      #  Calculate based on number of weeks wanted.  We count weeks
      #  or parts of weeks, so if invoked on Wed 10th with weeks set
      #  to 2, then we will calculate an end date of Sat 20th.
      #
      @end_date = date_of_saturday(options.weeks)
      puts "End date is #{@end_date}" if @options.verbose
    end
    #
    #  Need to make the next bit an option too.
    #
    @event_categories = [Eventcategory.find_by(name: "Lesson")]
    if block_given?
      yield self
    end
  end

  def date_of_saturday(weeks)
    #
    #  First we want the date of the Sunday of the current week.
    #
    Date.beginning_of_week = :sunday
    date = (Date.today.at_beginning_of_week - 1.day) + weeks.weeks
  end

  #
  #  Carry out the indicated checks.
  #
  def perform
    @start_date.upto(@end_date) do |date|
      events = Event.events_on(date, date, @event_categories)
      puts "#{events.count} events on #{date}." if @options.verbose
      events.each do |event|
        resources =
          event.all_atomic_resources.select { |r|
            r.class == Staff ||
              r.class == Pupil ||
              r.class == Location
          }
        clashing_events = Array.new
        resources.each do |resource|
#          puts "Starting on #{resource.name} at #{Time.now.strftime("%H:%M:%S")}."
          clashing_events +=
            resource.element.commitments_during(
              start_time:   event.starts_at,
              end_time:     event.ends_at,
              and_by_group: true).preload(:event).collect {|c| c.event}
        end
        clashing_events.uniq!
        puts "Event #{event.body} has #{clashing_events.count} clashes."
        clashing_events.each do |ce|
          puts ce.body
        end
      end
    end
  end

end

def finished(options, stage)
  if options.do_timings
    puts "#{Time.now.strftime("%H:%M:%S")} finished #{stage}."
  end
end

begin
  options = Options.new
  ClashChecker.new(options) do |checker|
    unless options.just_initialise
      finished(options, "initialisation")
      checker.perform
      finished(options, "processing")
    end
  end
rescue RuntimeError => e
  puts e
end


