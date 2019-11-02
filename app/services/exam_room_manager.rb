# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ExamRoomManager

  class RoomStore

    class RoomRecord
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
      @rooms = Hash.new
    end

    def note_instance(location, event)
      existing = @rooms[location.id]
      if existing
        existing.note_further_event(event)
      else
        @rooms[location.id] = RoomRecord.new(location, event)
      end
    end

    def each_room
      @rooms.each do |id, room_record|
        yield room_record
      end
    end

  end

  #
  #  Note that the end_date is inclusive.  Not best practice, but it
  #  matches what happens elsewhere in the processing.
  #
  def initialize(exam_cycle)
    @exam_cycle       = exam_cycle
  end

  #
  #  This method works as an iterator.  It expects to be passed a block
  #  to which it will yield each room record in turn.
  #
  def each_room_record
    events = @exam_cycle.selector_element.events_on(
      @exam_cycle.starts_on,
      @exam_cycle.ends_on,
      nil,
      nil,
      true,
      true,
      true)
    room_store = RoomStore.new
    events.each do |event|
      event.locations_even_tentative.each do |location|
        room_store.note_instance(location, event)
      end
    end
    room_store.each_room do |room_record|
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

  private

end

