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

class String
  def wrap(width = 78)
    self.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
  end

  def indent(spaces = 2)
    padding = " " * spaces
    padding + self.gsub("\n", "\n#{padding}").rstrip
  end
end

class ClashChecker

  CLASSES_TO_CHECK = [Pupil]

  def initialize(options)
    @options    = options
    @start_date = options.start_date
    if options.end_date
      @end_date = options.end_date
    else
      if options.ahead > 0
        #
        #  Being asked to work ahead by N weeks.  We will thus
        #  begin our processing on a Sunday, calculated forward.
        #
        #  If we are asked on a Friday to work forward by one
        #  week, then the processing will start on the Sunday in
        #  two days time.
        #
        #  Interestingly, the date when we want to start for --ahead N
        #  is one day after the date when we would end for --weeks N
        #
        @start_date = date_of_saturday(@start_date, options.ahead) + 1.day
        puts "Start date is #{@start_date}" if @options.verbose
      end
      #
      #  Calculate based on number of weeks wanted.  We count weeks
      #  or parts of weeks, so if invoked on Wed 10th with weeks set
      #  to 2, then we will calculate an end date of Sat 20th.
      #
      @end_date = date_of_saturday(@start_date, options.weeks)
      puts "End date is #{@end_date}" if @options.verbose
    end
    @event_categories = Eventcategory.where(clashcheck: true)
    if @event_categories.size > 0
      if @options.verbose
        puts "Checking event categories:"
        @event_categories.each do |ec|
          puts "  #{ec.name}"
        end
      end
    else
      puts "No event categories are flagged for clash checking."
      exit
    end
    @user_email_bodies = Hash.new
    if block_given?
      yield self
    end
  end

  def date_of_saturday(start_date, weeks)
    #
    #  First we want the date of the Sunday of the current week.
    #
    Date.beginning_of_week = :sunday
    date = (start_date.at_beginning_of_week - 1.day) + weeks.weeks
  end

  def generate_text(resources, clashing_events)
    result = Array.new
    clashing_events.each do |ce|
      result << "#{ce.body} (#{ce.duration_or_all_day_string})"
      ce_resources =
        ce.all_atomic_resources.select { |r|
          CLASSES_TO_CHECK.include?(r.class)
        }
      clashing_resources = resources & ce_resources
      #
      #  We have a mixture of types of resources, which we can't actually
      #  sort, so sort their elements instead.
      #
      result << clashing_resources.
                collect {|cr| cr.element}.
                sort.
                collect {|ce| ce.entity.name}.
                join(", ").
                wrap(78).
                indent(2)
    end
    result.join("\n")
  end

  #
  #  A method to accumulate e-mails for users who have asked for immediate
  #  notifications.  Note that we don't actually send them at this point,
  #  just accumulate them.
  #
  def notify_users(event, note_text)
    #
    #  We notify only staff who are directly involved - i.e. taking
    #  the lesson.  Any included via a group will not be notified.
    #
    #  To change that, make the line read:
    #
    #  event.staff(true).each do |staff|
    #
    event.staff.each do |staff|
      user = staff.corresponding_user
      if user && user.clash_immediate
        @user_email_bodies[user.id] ||= Array.new
        @user_email_bodies[user.id] << "Projected absences for #{event.body} on #{event.starts_at.strftime("%d/%m/%Y")}."
        @user_email_bodies[user.id] << note_text.indent(2)
      end
    end
  end

  #
  #  Carry out the indicated checks.
  #
  def perform
    non_clashing_categories = Eventcategory.where(busy: false).to_a
    non_clashing_categories.each do |ncc|
      puts "Events in category \"#{ncc.name}\" not regarded as clashing."
    end
    @start_date.upto(@end_date) do |date|
      #
      #  Given the way we are working, we throw away our cache and start
      #  a fresh one for each day.
      #
      mwds_cache = Membership::MWD_SetCache.new
      events =
        Event.events_on(
          date,                 # Start date
          date,                 # End date
          @event_categories,    # Event categories
          nil,                  # Event source
          nil,                  # Resource
          nil,                  # Owned by
          true)                 # Include non-existent
      puts "#{events.count} events on #{date}." if @options.verbose
      events.each do |event|
        notes = event.notes.clashes
        if event.non_existent
          #
          #  We never set the flag or attach a note to a suspended lesson,
          #  but it's possible that first we did that and then the lesson
          #  got suspended.  Check for that situation and correct it if
          #  found.
          #
          notes.each do |note|
            puts "Deleting note from non-existent #{event.body}." if @options.verbose
            note.destroy
          end
          if event.has_clashes
            event.has_clashes = false
            event.save
          end
        else
          resources =
            event.all_atomic_resources.select { |r|
              CLASSES_TO_CHECK.include?(r.class)
            }
          clashing_events = Array.new
          resources.each do |resource|
  #          puts "Starting on #{resource.name} at #{Time.now.strftime("%H:%M:%S")}."
            #
            #  Note that this next call won't pick up non-existent events
            #  because we haven't explicitly asked for them.
            #
            clashing_events +=
              resource.element.commitments_during(
                start_time:   event.starts_at,
                end_time:     event.ends_at,
                and_by_group: true,
                excluded_category: non_clashing_categories,
                cache:        mwds_cache).preload(:event).collect {|c| c.event}
          end
          clashing_events.uniq!
          clashing_events = clashing_events - [event]
          if clashing_events.size > 0
            note_text = generate_text(resources, clashing_events)
            puts "Clashes for #{event.body}." if @options.verbose
            puts note_text.indent(2) if @options.verbose
            if notes.size == 1
              #
              #  Just need to make sure the text is the same.
              #
              note = notes[0]
              if note.contents != note_text
                puts "Amending note on #{event.body}" if @options.verbose
                note.contents = note_text
                note.save
                notify_users(event, note_text)
              end
              unless event.has_clashes
                event.has_clashes = true
                event.save
              end
            else
              if notes.size > 1
                #
                #  Something odd going on here.  Should not occur.
                #
                puts "Destroying multiple notes for #{event.body}."
                notes.each do |note|
                  note.destroy
                end
              end
              #
              #  Create and save a new note.
              #
              note = Note.new
              note.title = "Predicted absences"
              note.contents = note_text
              note.parent = event
              note.owner  = nil
              note.visible_staff = true
              note.note_type = :clashes
              if note.save
                puts "Added note to #{event.body} on #{date}." if @options.verbose
                notify_users(event, note_text)
              else
                puts "Failed to save note on #{event.body}."
              end
              unless event.has_clashes
                event.has_clashes = true
                event.save
              end
            end
          else
            #
            #  No clashes.  Just need to make sure there is no note attached
            #  to the event.
            #
            notes.each do |note|
              puts "Deleting note from #{event.body}." if @options.verbose
              note.destroy
            end
            if event.has_clashes
              event.has_clashes = false
              event.save
            end
          end
  #        if clashing_events.size > 0
  #          puts "Event #{event.body} has #{clashing_events.count} clashes."
  #          clashing_events.each do |ce|
  #            puts ce.body
  #          end
  #        end
        end
      end
    end
  end

  #
  #  Do the actual sending of the queued up e-mails.
  #
  def send_emails
    @user_email_bodies.each do |key, texts|
      user = User.find(key)
      UserMailer.clash_notification_email(user.email, texts.join("\n")).deliver
    end
  end

  #
  #  Scan existing flagged events and send e-mail notifications to those
  #  who have requested them.
  #
  def summary_emails
    events = Event.beginning(@start_date).has_clashes
    events.each do |event|
      staff = event.all_atomic_resources.select { |r| r.class == Staff }
      #
      #  Force to array to avoid querying the d/b several times.
      #
      notes = event.notes.clashes.to_a
      if notes.size >= 1
        if notes.size > 1
          puts "Event #{event.body} on #{event.starts_at.strftime("%d/%m/%Y")} has more than one clash note."
        end
        notes.each do |note|
          staff.each do |staff|
            user = staff.corresponding_user
            if user &&
               (user.clash_daily || (user.clash_weekly && @options.weekly))
              @user_email_bodies[user.id] ||= Array.new
              @user_email_bodies[user.id] << "Projected absences for #{event.body} on #{event.starts_at.strftime("%d/%m/%Y")}."
              @user_email_bodies[user.id] << note.contents.indent(2)
            end
          end
        end
      else
        puts "Event #{event.body} on #{event.starts_at.strftime("%d/%m/%Y")} is flagged as clashing but has no note."
      end
    end
    send_emails
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
      if options.summary
        checker.summary_emails
        finished(options, "summary e-mails")
      else
        checker.perform
        finished(options, "processing")
        checker.send_emails
        finished(options, "sending e-mails")
      end
    end
  end
rescue RuntimeError => e
  puts e
end


