#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#

require 'ostruct'
require 'nokogiri'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

require_relative 'common/xmlimport'

require_relative 'socs/element_engine'
require_relative 'socs/location_engine'
require_relative 'socs/property_engine'
require_relative 'socs/options'
require_relative 'socs/socs_fixture'

SOCS_IMPORT_DIR = 'import/socs/Current'
DUMMY_SOURCE_ID_VALUE = 123456

#
#  And now we start.
#
element_engine = ElementEngine.new
location_engine = LocationEngine.new
property_engine = PropertyEngine.new
options = Options.new(element_engine)

eventsource = Eventsource.find_by(name: "SOCS")
unless eventsource
  puts "Eventsource SOCS not found"
  exit 1
end

eventcategory = Eventcategory.find_by(name: options.event_category_name)
unless eventcategory
  puts "Eventcategory #{options.event_category_name} not found."
  exit 2
end

if options.user_id
  default_owner = User.find_by(id: options.user_id)
  unless default_owner
    puts "No user with id #{options.user_id} can be found"
    exit 3
  end
else
  default_owner = nil
end

#
#  Start of main processing.
#
full_dir_path = Rails.root.join(SOCS_IMPORT_DIR)
xml = Nokogiri::XML(File.open(File.expand_path("data.xml", full_dir_path)))

fixture_set = SocsFixtureSet.new(xml, options)
if fixture_set.empty?
  puts "No fixtures found."
else
  puts "Got #{fixture_set.fixtures.count} fixtures" if options.verbose
  #
  #  What dates to work between?
  #
  start_date = options.start_date
  if options.end_date
    end_date = options.end_date
  else
    end_date = fixture_set.last_date
  end
  if end_date < start_date
    puts "End date (#{end_date}) is less than start date (#{start_date}) - aborting."
  else
    events_created = 0
    events_deleted = 0
    start_date.upto(end_date) do |date|
      puts "Processing #{date.to_s(:dmy)}" if options.verbose
      #
      #  Find all existing events on this day for our source.
      #
      #  Note the to_a on the end, which is quite important.  We want an
      #  array from which we will subsequently *remove* the entries
      #  which we want to keep.
      #
      #  If we call .delete() on something which is still a selector,
      #  then we delete the element which we wanted to keep from the
      #  database.
      #
      existing_events =
        Event.events_on(date,          # Start date
                        nil,           # End date
                        nil,           # Categories
                        eventsource,   # Our event source
                        nil,           # Resource
                        nil,           # Owner
                        true).includes(:commitments).to_a     # And non-existent
      #
      #  And what do we want to have on this date?
      #
      wanted = fixture_set.fixtures_on(date)
#      puts "Existing - #{existing_events.collect {|e| e.source_id}.sort.join(",")}"
#      puts "Wanted   - #{wanted.collect {|f| f.socs_id}.sort.join(",")}"
      global_element_ids = options.attached_elements.collect {|e| e.id}
      wanted.each do |fixture|
        #
        #  We need to find the property_element immediately because
        #  it can affect the ownership of the event.
        #
        property_element = property_engine.find(fixture.sport)
        if property_element && property_element.owned?
          calculated_owner = property_element.owners.first || default_owner
        else
          calculated_owner = default_owner
        end
        existing_event =
          existing_events.detect {|e| e.source_id == fixture.socs_id}
        if existing_event
          #
          #  Already there - make sure it matches
          #
          do_save = false
          if existing_event.body != fixture.event_body
            existing_event.body = fixture.event_body
            do_save = true
          end
          if existing_event.eventcategory != eventcategory
            existing_event.eventcategory = eventcategory
            do_save = true
          end
          if existing_event.starts_at != fixture.starts_at
            existing_event.starts_at = fixture.starts_at
            do_save = true
          end
          if existing_event.ends_at != fixture.ends_at
            existing_event.ends_at = fixture.ends_at
            do_save = true
          end
          if existing_event.all_day != fixture.all_day
            existing_event.all_day = fixture.all_day
            do_save = true
          end
          if existing_event.owner != calculated_owner
            #
            #  Note that we change the owner without going back and
            #  rethinking any of the permissions.  This is deliberate.
            #  We might want to do an initial load as system events
            #  (bypassing checks) but then set all the events to a
            #  particular owner for all future processing.
            #
            existing_event.owner = calculated_owner
            do_save = true
          end
          if do_save
            existing_event.save!
          end
          #
          #  Remove from the array of existing events so it doesn't
          #  get deleted later.
          #
          existing_events.delete(existing_event)
        else
          #
          #  Need to create it from scratch.
          #
          new_event = Event.create!({
            body:          fixture.event_body,
            eventcategory: eventcategory,
            eventsource:   eventsource,
            starts_at:     fixture.starts_at,
            ends_at:       fixture.ends_at,
            all_day:       fixture.all_day,
            source_id:     fixture.socs_id,
            owner:         calculated_owner
          })
          events_created += 1
          existing_event = new_event
        end
        #
        #  Now ensure the necessary commitments.  These are:
        #
        #  1. Any element specified on the command line.
        #  2. The appropriate fixture property.
        #  3. Any identified home locations.
        #
        element_ids = global_element_ids.dup
        if property_element
          element_ids << property_element.id
        end
        fixture.home_locations.each do |hl|
          location_element = location_engine.find(hl)
          if location_element
            element_ids << location_element.id
          end
        end
        #
        #  It's just possible something might have been specified
        #  twice somehow.
        #
        element_ids.uniq!
        #
        #  And ensure them.
        #
        #  Note that we put a dummy value in the source_id for each
        #  of our commitments and we don't touch any other ones which we
        #  find.
        #
        #
        #  Check first for those which we are going to destroy.
        #
        commitments_to_destroy = []
        existing_event.commitments.each do |c|
          if (c.source_id == DUMMY_SOURCE_ID_VALUE) &&
              !element_ids.include?(c.element_id)
            commitments_to_destroy << c
          end
        end
        #
        #  And then add any necessary new ones.
        #
        element_ids.each do |ei|
          unless existing_event.commitments.detect {|c| c.element_id == ei}
            new_commitment = existing_event.commitments.new({
              element_id: ei,
              source_id:  DUMMY_SOURCE_ID_VALUE
            })
            if calculated_owner
              new_commitment.set_appropriate_approval_status_for(calculated_owner)
            end
            new_commitment.save!
          end
        end
        #
        #  And do the actual destroying.
        #
        commitments_to_destroy.each do |c|
          c.destroy
        end
        #
        #  And what about a note?
        #
        note_text = fixture.note_text
        existing_note = existing_event.notes.socs.first
        if existing_note
          if existing_note.contents != note_text
            existing_note.contents = note_text
            existing_note.save!
          end
        else
          unless note_text.blank?
            existing_event.notes.create!({
              contents:      note_text,
              visible_guest: true,
              note_type:     :socs
            })
          end
        end
          
      end
      #
      #  And any left now in the "existing" array are surplus.
      #
      unless existing_events.count == 0
        puts "Deleting #{existing_events.count} events on #{date.to_s(:dmy)}"
        events_deleted += existing_events.count
        existing_events.each do |event|
          event.destroy
        end
      end
    end
    puts "#{events_created} events created and #{events_deleted} events deleted." if options.verbose
    if options.list_missing
      location_engine.list_missing
    end
  end
end

exit

puts "Sports"
fixture_set.sports.sort.each do |sport|
  puts "  #{sport}"
end

puts "Home locations"
fixture_set.home_locations.sort.each do |hl|
  location = location_engine.find(hl)
  puts "  #{hl} (#{ location ? "found" : "not found" })"
end


puts "Events"
fixture_set.fixtures.select {|f| f.away?}.each do |fixture|
  puts "  #{fixture.event_body}"
end
