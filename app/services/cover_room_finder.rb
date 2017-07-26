# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class CoverRoomFinder

  class CandidateRoom
    attr_reader :name, :element_id

    def initialize(name, element_id)
      @name = name
      @element_id = element_id
    end

  end

  class CandidateRoomGroup
    attr_reader :name, :rooms

    def initialize(name)
      @name = name
      @rooms = Array.new
    end

    def <<(location)
      @rooms <<
        CandidateRoom.new(location.short_name, location.element.id)
    end
  end

  def initialize(event)
    @event = event
    @group_element = Setting.room_cover_group_element
    if @group_element
      @group = @group_element.entity
      puts("Free rooms group is #{@group_element.name}, group id #{@group_element.entity.id}")
      @ff = Freefinder.new({
        element:    @group_element,
        on:         @event.starts_at.to_date,
        start_time: @event.starts_at,
        end_time:   @event.ends_at
      })
    else
      @ff = nil
    end
  end

  def find_rooms
    if @ff
      @ff.do_find
      #
      #  There shouldn't be anything other than locations in our group,
      #  but just in case someone has added something odd, filter to
      #  make sure we have just locations.  We will later be matching
      #  them up by entity_id and if we had a mix of entity_types
      #  then it's just possible that we'd get a false match.
      #
      free_room_ids =
        @ff.free_elements.
            select {|e| e.entity_type == "Location"}.
            collect {|e| e.entity_id}
      #
      #  We now have a list of all the free rooms, but we'd really like
      #  them grouped.  The idea is that you have one master group of
      #  rooms, which itself contains a lot of groups, each of which
      #  then contains the actual rooms.  The Freefinder code has
      #  flattened this to find the free rooms, but now we'd like
      #  to get the structure back.  We could have created one freefinder
      #  for each sub-group, but that would mean finding and processing
      #  all the overlapping events N times.  This way I believe will
      #  be quicker.
      #
      sub_groups =
        @group.members(@event.starts_at.to_date,
                       false).select {|e| e.instance_of?(Group)}
      result = Array.new
      sub_groups.each do |sg|
        crg = CandidateRoomGroup.new(sg.name)
        sg.members(@event.starts_at.to_date, false).
           select{|e| e.instance_of?(Location)}.each do |l|
          if free_room_ids.include?(l.id)
            crg << l
          end
        end
        result << crg
      end
      result
    else
      []
    end
  end
end

