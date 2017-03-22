#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'optparse'
require 'optparse/date'
require 'date'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

require_relative 'options'

class NotifierRunner

  def initialize(options)
    @options    = options
    @start_date = options.start_date
    if options.weekly
      @run_type = :weekly
      @end_date = date_of_saturday(@start_date)
    else
      @run_type = :daily
      @end_date = @start_date
    end
    if block_given?
      yield self
    end
  end

  def date_of_saturday(start_date)
    #
    #  First we want the date of the Sunday of the current week.
    #
    Date.beginning_of_week = :sunday
    date = (start_date.at_beginning_of_week - 1.day) + 1.week
  end

  def perform
    notifier = Notifier.new({
      start_date: @start_date,
      end_date:   @end_date
    })
    if notifier.valid?
      notifier.execute(@run_type)
      if @options.verbose
        if notifier.staff_entries.size > 0
          notifier.staff_entries.sort.each do |se|
            puts "  #{se.staff.name} (#{se.instances.count})#{ se.notify?(@run_type) ? "" : " - opted out"}"
          end
        else
          puts "No notification sent."
        end
      end
    else
      puts "Notifier is not valid."
      notifier.errors.full_messages.each do |message|
        puts message
      end
    end
  end

end

begin
  options = Options.new
  NotifierRunner.new(options) do |nr|
    nr.perform
  end
rescue RuntimeError => e
  puts e
end


