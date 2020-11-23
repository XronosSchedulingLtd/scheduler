#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'tod'

class FreeSlotFinder

  class FSFResult < TimeSlotSet

    attr_accessor :mins_required

    attr_reader :element_ids

    def initialize(*params)
      super
      @mins_required = 0
      @element_ids = Array.new
    end

    def note_elements(elements)
      @element_ids = elements.collect {|e| e.id}
    end

    def at_least_mins(mins)
      result = super
      result.mins_required = self.mins_required
      result
    end

    def to_partial_path
      'fsf_result'
    end

  end

  def initialize(elements, mins_required, start_time, end_time)
    elements.each do |e|
      unless e.instance_of?(Element)
        raise ArgumentError.new("Not an element - #{e.class}")
      end
    end
    @elements = elements
    if mins_required.kind_of?(Integer) && mins_required > 0
      @mins_required = mins_required
    else
      raise ArgumentError.new("mins_required must be a positive integer")
    end
    case start_time
    when String
      @start_time = Tod::TimeOfDay.parse(start_time)
    when Tod::TimeOfDay
      @start_time = start_time
    else
      raise ArgumentError.new("Invalid start time")
    end
    case end_time
    when String
      @end_time = Tod::TimeOfDay.parse(end_time)
    when Tod::TimeOfDay
      @end_time = end_time
    else
      raise ArgumentError.new("Invalid end time")
    end
    if @end_time < @start_time
      raise ArgumentError.new("Backwards time slot")
    end
  end

  def slots_on(date)
    free_times = FSFResult.new(date, [@start_time, @end_time])
    free_times.mins_required = @mins_required
    elements = flatten_on(date, @elements)
    free_times.note_elements(elements)
    elements.each do |element|
      commitments =
        element.commitments_on(startdate: date).preload(event: :eventcategory)
      commitments.each do |commitment|
        event = commitment.event
        unless Eventcategory.non_busy_categories.include?(event.eventcategory)
          free_times -= event.time_slot_on(date)
        end
      end
    end
    free_times
  end

  private

  #
  #  Takes an array of elements, some of which may be groups, and flattens
  #  it to an array of atomic elements - no groups.
  #
  def flatten_on(date, elements)
    result = []
    elements.each do |element|
      if element.entity_type == "Group"
        members = element.entity.members(date, true, true)
        members.each do |member|
          result << member.element
        end
      else
        result << element
      end
    end
    result.uniq
  end

end
