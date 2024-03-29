# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class CoverRoomFinder

  class CandidateRoom
    attr_reader :name, :element_id, :covering

    def initialize(name, element_id, covering = false)
      @name       = name
      @element_id = element_id
      @covering   = covering
    end

  end

  class CandidateRoomGroup
    attr_reader :name, :rooms, :available

    def initialize(name, available = true)
      @name      = name
      @rooms     = Array.new
      @available = available
    end

    def add(location, covering = false)
      @rooms <<
        CandidateRoom.new(location.element_name, location.element.id, covering)
    end

    def empty?
      @rooms.empty?
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
      #
      #  Is there already a room cover set up?  If so then we add that
      #  to our list of "free" rooms (even though it isn't) and flag
      #  it as the currently selected one.
      #
      @location_covering_commitment =
        @event.commitments.covering_location.take
      if @location_covering_commitment
        @cover_location_id = @location_covering_commitment.element.entity_id
      end
    else
      @ff = nil
    end
  end

  def find_rooms(and_unavailable = false)
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
      availables = Array.new
      unavailables = Array.new
      sub_groups.each do |sg|
        available_ones   = CandidateRoomGroup.new(sg.name)
        unavailable_ones = CandidateRoomGroup.new(sg.name, false)
        sg.members(@event.starts_at.to_date, false).
           select{|e| e.instance_of?(Location)}.each do |l|
          if free_room_ids.include?(l.id)
            available_ones.add(l)
          elsif l.id == @cover_location_id
            #
            #  This is the location currently set as providing cover.
            #  If it has just the one commitment then it's us and the
            #  room counts as available.  If it has more then it is
            #  technically unavailable.
            #
            if count_commitments(l) > 1
              unavailable_ones.add(l, true)
            else
              available_ones.add(l, true)
            end
          else
            unavailable_ones.add(l)
          end
        end
        #
        #  "Available" groups get displayed even if empty.
        #
        availables << available_ones
        #
        #  "Unavailable" ones do not.
        #
        unavailables << unavailable_ones unless unavailable_ones.empty?
      end
      if and_unavailable && !unavailables.empty?
        availables + [CandidateRoomGroup.new("---All below here are in use---", false)] + unavailables
      else
        availables
      end
    else
      []
    end
  end

  private

  #
  #  How many commitments does the indicated location have during our
  #  target time period?
  #
  def count_commitments(location)
    non_busy_categories = Eventcategory.non_busy_categories
    location.element.commitments_during(
      start_time:        @event.starts_at,
      end_time:          @event.ends_at,
      and_by_group:      false,
      excluded_category: non_busy_categories).size
  end

end

