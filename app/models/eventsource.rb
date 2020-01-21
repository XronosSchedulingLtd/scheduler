# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Eventsource < ActiveRecord::Base

   validates :name, presence: true
   validates :name, uniqueness: true

   has_many :events, dependent: :destroy
   has_many :proto_events, dependent: :destroy

   @@manual_source_id = nil

   def <=>(other)
     self.name <=> other.name
   end

   def can_destroy?
     self.events.count == 0
   end

   #
   #  Maintenance method to remove all the events from a given event
   #  source part way through an era.  Just for use when testing
   #  a mid-year MIS change.
   #
   def purge_events(from_date = Date.today)
     era = Setting.current_era
     events = Event.events_on(from_date,
                              era.ends_on,
                              nil,
                              self,
                              nil,
                              nil,
                              true)
     puts "Found #{events.count} events to purge."
     events.each do |event|
       event.destroy
     end
     nil
   end

   #
   #  Cache and pass back the id of the manual event source.
   #  This is set up in the initial seed data and should not
   #  change thereafter.
   #
   def self.manual_source_id
     unless @@manual_source_id
       manual_source = Eventsource.find_by(name: "Manual")
       if manual_source
         @@manual_source_id = manual_source.id
       end
     end
     @@manual_source_id
   end
end
