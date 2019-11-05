# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'tod'

class ExamRoomManager

  class SlotSet
    #
    #  Stores an array of slots - time periods within the day.
    #

    class Slot
      attr_reader :starts_at, :ends_at, :id

      def initialize(starts_at, ends_at, id = 0) # Both Tod::TimeOfDay objects
        @starts_at = starts_at
        @ends_at   = ends_at
        @id        = id
      end

      def self.from_event(event)
        Slot.new(Tod::TimeOfDay(event.starts_at), Tod::TimeOfDay(event.ends_at))
      end

      #
      #  Does this slot overlap with another one?
      #
      def overlaps?(other)
        @starts_at < other.ends_at && @ends_at > other.starts_at
      end

      #
      #  Return a new slot representing the overlap between this slot
      #  and another.  nil if they don't overlap.
      #
      def intersection(other)
        if self.overlaps?(other)
          #
          #  We want the later of the two start times, and the earlier
          #  of the two end times.
          #
          starts_at =
            @starts_at > other.starts_at ? @starts_at : other.starts_at
          ends_at =
            @ends_at < other.ends_at ? @ends_at : other.ends_at
          Slot.new(starts_at, ends_at, self.id)
        else
          Rails.logger.debug("Doesn't overlap")
          nil
        end
      end

      def merge_times(other)
        if other.starts_at < @starts_at
          @starts_at = other.starts_at
        end
        if other.ends_at > @ends_at
          @ends_at = other.ends_at
        end
      end

      def <=>(other)
        if other.instance_of?(Slot)
          if self.starts_at == other.starts_at
            self.ends_at <=> other.ends_at
          else
            self.starts_at <=> other.starts_at
          end
        else
          nil
        end
      end

      def timings_for(date)
        return [@starts_at.on(date), @ends_at.on(date)]
      end

    end

    def initialize
      @slots = Array.new
    end

    def add(new_slot)
      @slots << new_slot
    end

    def each
      @slots.each do |slot|
        yield slot
      end
    end

    def add_with_merge(new_slot)
      #
      #  It's tempting to delete all the overlapping slots as we
      #  go, but that doesn't work well whilst you're iterating through
      #  the array.
      #
      #  Do them in one go at the end.
      #
      @slots.each do |existing_slot|
        if new_slot.overlaps?(existing_slot)
          new_slot.merge(existing_slot)
        end
      end
      #
      #  The overlapping slots will still overlap - even more so
      #  now our new slot may have got bigger.
      #
      @slots.delete_if { |s| new_slot.overlaps?(s) }
      @slots << new_slot
    end

    def overlapping_slots(given_slot)
      @slots.select { |s| s.overlaps?(given_slot) }
    end

    #
    #  Given two sets of slots, mask one against the other and return
    #  a new set.  If our own set has overlapping entries then we will
    #  generate one for each of our own.
    #
    def mask_with(other_set)
      new_set = SlotSet.new
      @slots.each do |slot|
        other_set.overlapping_slots(slot).each do |overlapping_slot|
          new_set.add(slot.intersection(overlapping_slot))
        end
      end
      new_set
    end

    #
    #  Take an array of events and build a SlotSet, merging any events
    #  which overlap with each other.
    #
    def self.from_event_records(event_records)
      ss = SlotSet.new
      event_records.each do |event_record|
        ss.add_with_merge(Slot.from_event(event_record.event))
      end
      ss
    end

    #
    #  Likewise for an array of RotaSlots, but no merging in this case
    #
    def self.from_rota_slots(rota_slots)
      ss = SlotSet.new
      rota_slots.each do |rs|
        ss.add(Slot.new(rs.starts_at_tod, rs.ends_at_tod, rs.id))
      end
      ss
    end

  end


  class RoomStore

    class EventRecord
      attr_reader :event
      #
      #  This is for storing one event/location pairing.  Note that
      #  each event may (probably does) use more than one location,
      #  so more than one of these records will exist per event.
      #
      def initialize(event, location)
        @event    = event
        @location = location
      end
    end

    class RoomRecord
      #
      #  This is for storing one room, plus a list of all the events
      #  which use it.
      #
      attr_reader :location

      def initialize(location, event)
        @location = location
        @events = [event]
      end

      def note_further_event(event)
        @events << event
      end

      def first_date
        @events.sort.first.starts_at.to_date
      end

      def last_date
        #
        #  This is slightly more complex because it might be an all day
        #  event ending at exactly midnight.  We also need to sort by ends_at
        #  because that's what matters.  And an event potentially has no
        #  ends_at, in which case it is an instantaneous event.
        #
        last_event = @events.sort_by {
          |event| event.ends_at ? event.ends_at : event.starts_at
        }.last
        if last_event.ends_at.midnight?
          last_event.ends_at.to_date - 1.day
        else
          last_event.ends_at.to_date
        end
      end

    end

    def initialize
      @rooms_by_location_id = Hash.new
      @events_by_date_and_location_id = Hash.new
    end

    def note_instance(location, event)
      #
      #  Store first by location id.
      #
      existing = @rooms_by_location_id[location.id]
      if existing
        existing.note_further_event(event)
      else
        @rooms_by_location_id[location.id] = RoomRecord.new(location, event)
      end
      #
      #  And then by date and location id.
      #
      date = event.starts_at.to_date
      date_entry = @events_by_date_and_location_id[date] ||= Hash.new
      date_location_entry = date_entry[location.id] ||= Array.new
      date_location_entry << EventRecord.new(event, location)
    end

    def each_room
      @rooms.each do |id, room_record|
        yield room_record
      end
    end

    def events_on_for(date, location)
      date_entry = @events_by_date_and_location_id[date]
      if date_entry
        date_location_entry = date_entry[location.id]
        if date_location_entry
          date_location_entry
        else
          []
        end
      else
        []
      end
    end

  end

  #
  #  Note that the end_date is inclusive.  Not best practice, but it
  #  matches what happens elsewhere in the processing.
  #
  def initialize(exam_cycle)
    @exam_cycle = exam_cycle
    #
    #  Let's do our room finding now.  Then we have it whatever we're
    #  asked to do later.
    #
    @room_store = RoomStore.new
    if @exam_cycle.selector_element
      events = @exam_cycle.selector_element.events_on(
        @exam_cycle.starts_on,
        @exam_cycle.ends_on,
        nil,
        nil,
        true,
        true,
        true)
      events.each do |event|
        event.locations_even_tentative.each do |location|
          @room_store.note_instance(location, event)
        end
      end
    end
  end

  #
  #  This method works as an iterator.  It expects to be passed a block
  #  to which it will yield each room record in turn.
  #
  def each_room_record
    @room_store.each_room do |room_record|
      yield room_record
    end
    nil
  end

  #
  #  Generate (and cache) a list of existing rooms for the exam cycle.
  #
  def existing_rooms
    unless @existing_rooms
      @existing_rooms = Array.new
      @exam_cycle.proto_events.each do |pe|
        pe.proto_commitments.includes(element: :entity).each do |pr|
          if pr.element.entity_type == 'Location'
            room = pr.element.entity
            unless @existing_rooms.include?(room)
              @existing_rooms << room
            end
          end
        end
      end
    end
    @existing_rooms
  end

  #
  #  Calculate the slots for a given date, making use of both the
  #  exam template and any configured selector element on the
  #  exam slot.
  #
  #  Note that this works only for an exam related proto_event.
  #
  def slots_for(date, location)
    selector_element = @exam_cycle.selector_element
    if selector_element
      #
      #  We need all relevant events for this selector element in the
      #  indicated day, and then we will mask the rota slots against
      #  them.
      #
      #  The slots we eventually generate each have to be entirely
      #  contained within a rota slot, but we might have more than
      #  one within that duration.  One exam session might end, then
      #  another start within the duration of the rota slot.  It's
      #  even theoretically possible that one could have a really
      #  short exam session entirely within the rota slot.
      #
      #  Rota slots       ------------------  ----------------------
      #  Exam sessions  +------   -----   ----------  -------- -------
      #  Result           -----   -----   --  ------  -------- -----
      #
      #  It occurs to me that someone might even create overlapping
      #  exam sessions for the same room.
      #
      #  Exam session   ------      ----------  -------- -------
      #  Exam session       ----------  
      #
      #  In which case I should probably merge the exam sessions
      #  before doing the masking operation.  In the above case,
      #  invigilators are needed from the start of the 1st session
      #  to the end of the third.
      #
      #  This could realistically happen if someone enters the individual
      #  exams which are to be taken.  OK - another step.
      #
      #  We do *not* attempt to do the same thing for the rota slots
      #  which have been defined.  If someone wants to make two of those
      #  overlap then they may have a good reason.  The end result will
      #  be (assuming there is some sort of exam in the overlap time)
      #  two invigilation slots.
      #
      masking_events = @room_store.events_on_for(date, location)
      masking_slots = SlotSet.from_event_records(masking_events)
      our_slots =
        SlotSet.from_rota_slots(
          @exam_cycle.default_rota_template.slots_for(date))
      resulting_slots = our_slots.mask_with(masking_slots)
      resulting_slots.each do |rs|
        yield rs
      end
    else
      #
      #  Without a selector element, the best we can do is provide
      #  the slots direct from the rota template.
      #
      @exam_cycle.default_rota_template.slots_for(date) do |s|
        yield s
      end
    end
  end

  private

end

