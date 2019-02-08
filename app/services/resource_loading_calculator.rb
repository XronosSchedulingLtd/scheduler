# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ResourceLoadingCalculator

  class Accumulator < Hash

    def [](key)
      super || (self[key] = Array.new)
    end

  end

  class Loading

    include Comparable

    attr_reader :used, :out_of, :spare

    def initialize(used, out_of)
      @used   = used
      @out_of = out_of
      @spare  = out_of - used
    end

    def <=>(other)
      if other.instance_of?(Loading)
        #
        #  The lower the number of spares, the bigger our effective
        #  loading.  Hence reversed.
        #
        other.spare <=> self.spare
      else
        nil
      end
    end

    def to_s(string = "of")
      "#{@used} #{string} #{@out_of}"
    end

    def overload?
      @spare < 0
    end

    NoLoading = Loading.new(0, 9999)

  end

  class RequestableResourceGroup
    #
    #  This exists only so we can calculate the members of
    #  a group just once per day, rather than doing it
    #  for each individual timeslot.
    #
    attr_reader :entity, :atomic_members, :overall

    def initialize(entity, date, overall = false)
      @entity = entity
      @atomic_members = entity.members(@date, true, true)
      @overall = overall
    end

    def size
      @atomic_members.size
    end

    def entity_name
      if @overall
        "Overall"
      else
        @entity.name
      end
    end

    def one_of_ours?(element)
      #
      #  Is the indicated element either our group itself, or
      #  one of its constituent members?
      #
      @entity.element == element ||
        @atomic_members.detect {|am| am.element == element}
    end

  end

  class TimeSlot

    class ResourceTally
      attr_reader :requestee, :other_commitment_count, :request_count

      def initialize(requestee)
        @requestee = requestee
        @other_commitment_count = 0
        @request_count          = 0
      end

      def note_commitment_for(element)
        #
        #  There is a commitment for the indicated element.
        #  Does it affect our totals?
        #
        if @requestee.one_of_ours?(element)
          @other_commitment_count += 1
        end
      end

      def note_request(request)
        @request_count += request.quantity
      end

      #
      #  Don't call this before you have finished passing in all
      #  the requests/commitments.  The result will be calculated
      #  once and then cached.
      #
      def loading
        unless @loading
          @loading = Loading.new(@request_count,
                                 @requestee.size - @other_commitment_count)
        end
        @loading
      end
    end

    class Timing
      attr_reader :start_time, :end_time

      def initialize(start_time, end_time)
        @start_time = start_time
        @end_time   = end_time
      end

      def to_s
        if @end_time == @start_time + 1.day
          "All day"
        else
          "#{@start_time.to_s(:hhmm)} to #{@end_time.to_s(:hhmm)}"
        end
      end

      def <=>(other)
        if other.instance_of?(Timing)
          result = self.start_time <=> other.start_time
          if result == 0
            result = self.end_time <=> other.end_time
          end
          return result
        else
          return nil
        end
      end
    end

    attr_reader :timing, :events

    #
    #  Holds one interval in the day.
    #
    def initialize(start_time, end_time, events, requestees)
      @timing = Timing.new(start_time, end_time)
      @events = events.select {|event|
        event.exists_during?(start_time, end_time)
      }
      #
      #  Requesters are the groups for which there may be requests.
      #  They are the main thing on which we are going to report.
      #
      #  If there is more than one, then the last one is a summary
      #  entry and is treated specially.
      #
      if requestees.size > 1
        @requestees = requestees[0...-1]
        @summary_requestee = requestees.last
      else
        @requestees = requestees
        @summary_requestee = nil
      end
    end

    def calculate(joiners_by_event_id, elements_by_commitment_id)
      @tally_hash = Hash.new
      @requestees.each do |r|
        #puts "#{r.entity.name} has #{r.size} original resources."
        @tally_hash[r.entity.element.id] = ResourceTally.new(r)
      end
      if @summary_requestee
        @summary_tally = ResourceTally.new(@summary_requestee)
      else
        @summary_tally = nil
      end
      #
      #  I need to go through all my events, making a tally of how
      #  many of each type of resource each one involves.
      #
      @events.each do |event|
        joiners = joiners_by_event_id[event.id]
        if joiners.nil?
          Rails.logger.error("No joiners found for event #{event.id}")
        else
          joiners.each do |joiner|
            case joiner
            when Commitment
              elements = elements_by_commitment_id[joiner.id]
              if elements
                elements.each do |element|
                  #
                  #  We keep a tally for groups rather than for
                  #  individual items.  Therefore we offer each of
                  #  our tallying objects the chance to count
                  #  this commitment.
                  #
                  @tally_hash.each do |key, entry|
                    entry.note_commitment_for(element)
                  end
                  if @summary_tally
                    @summary_tally.note_commitment_for(element)
                  end
                end
              else
                Rails.logger.error("Elements not found for commitment id #{joiner.id}")
              end
            when Request
              tally_entry = @tally_hash[joiner.element_id]
              if tally_entry
                tally_entry.note_request(joiner)
              else
                Rails.logger.error("Request #{joiner.id} for element #{joiner.element_id} not matched.")
              end
              if @summary_tally
                @summary_tally.note_request(joiner)
              end
            end
          end
        end
      end
      #
      #  What totals do I have?
      #
      #puts "For timeslot #{self.to_s}"
      #@tally_hash.each do |key, entry|
      #  puts "#{entry.requestee.entity.name} has #{entry.other_commitment_count} commitments and #{entry.request_count} requests"
      #end
    end

    #
    #  What is the loading for the indicated requestee in our timeslot?
    #
    def loading_for(requestee)
      entry = @tally_hash[requestee.entity.element.id]
      if entry
        entry.loading
      else
        Loading::NoLoading
      end
    end

    def summary_loading
      if @summary_tally
        @summary_tally.loading
      else
        Loading::NoLoading
      end
    end

    def to_s
      @timing.to_s
    end

    def self.construct(times, events, requestees)
      #
      #  Build and return an array of timeslots to match the supplied
      #  times.  There must be at least two times, or we return an empty
      #  array.
      #
      #  Times should already be sorted and unique, or chaos will happen.
      #
      result = []
      if times.size > 1
        #
        #  N times will produce N-1 TimeSlots.
        #
        (times.size - 1).times do |index|
          result << TimeSlot.new(times[index],
                                 times[index + 1],
                                 events,
                                 requestees)
        end
      end
      result
    end
  end

  class DayLoading

    LoadingReport = Struct.new(:name, :element, :loading, :timing)

    class LoadingReport
      def to_partial_path
        'loading_report'
      end
    end

    attr_reader :maximum_loading_reports, :overloads, :date

    def initialize(element, date)
      #
      #  It might seem a bit silly at first sight, but we need to leave
      #  a trail of breadcrumbs to work back from the events which we find
      #  to the commitments/requests which enabled us to find them.
      #
      #  This is because we want to get back to them efficiently.  Given
      #  the events list we could then keep hitting the database again
      #  to find *all* the corresponding commitments/requests and then
      #  filter those but it would be much less efficient, and a lot more
      #  work.
      #
      #  In particular, working back to the right element from a commitment
      #  is really hard, because the commitment might not link to the
      #  element - it might link to a group containing the element.
      #
      @element = element
      @date = date
      @maximum_loading_reports = Array.new
      @overloads = Array.new
      all_entities = [@element.entity]
      if @element.entity.instance_of?(Group)
        all_entities += @element.entity.members(@date)
      end
      #
      #  Now, accumulate all the requests which we can find for any entity
      #  which can have requests.
      #
      requests = []
      requestees = []
      all_entities.select {|e| e.can_have_requests?}.each do |e|
        requests +=
          e.element.requests.during(@date, @date + 1.day).includes(:event).to_a
        requestees << RequestableResourceGroup.new(e, date)
      end
      #
      #  If we have nested resource groups then add another entry for
      #  a summary loading calculation.
      #
      if requestees.size > 1
        requestees << RequestableResourceGroup.new(@element.entity, date, true)
      end
      #puts "Got #{requests.size} requests"
      #
      #  And commitments for anything atomic.  Commitments for groups
      #  will be picked up by my standard recursion code - even groups
      #  outside our current nested tree.
      #
      #  Note that the same commitment can appear more than once, if it's
      #  a commitment for a group.
      #
      all_commitments = Array.new
      elements_by_commitment_id = Accumulator.new
      all_entities.select {|e| !e.instance_of?(Group)}.each do |e|
        commitments =
          e.element.commitments_on(startdate: @date).
                    standalone.
                    includes(:event).
                    to_a
        unless commitments.empty?
          #puts "Found #{commitments.size} standalone commitments for #{e.element.name}"
          all_commitments += commitments
          commitments.each do |c|
            elements_by_commitment_id[c.id] << e.element
          end
        end
      end
      all_commitments.uniq!
      #puts "Found #{all_commitments.size} standalone commitments in total."
      #
      #  Now make an array of all the events in which we have an interest.
      #
      all_events =
      (
        requests.collect {|r| r.event} +
        all_commitments.collect {|c| c.event}
      ).uniq.sort
      #
      #  Also need to be able to work back from an event to *all* the
      #  commitments or requests which referenced it.
      #
      joiners_by_event_id = Accumulator.new
      requests.each do |r|
        joiners_by_event_id[r.event_id] << r
      end
      all_commitments.each do |c|
        joiners_by_event_id[c.event_id] << c
      end
      unless all_events.empty?
        #
        # And work out all their start and end times on this date.
        #
        times = Array.new
        all_events.each do |event|
          times << event.start_time_on(@date)
          times << event.end_time_on(@date)
        end
        times.sort!
        times.uniq!
        #times.each do |t|
        #  puts "Time is #{t}"
        #end
        @timeslots = TimeSlot.construct(times, all_events, requestees)
        #@timeslots.each do |ts|
        #  puts "Timeslot from #{ts.to_s}:"
        #  puts "#{ts.events.size} events"
        #end
        #
        #  And now we have our timeslots we can work through them
        #  calculating the loading for each one.  We also keep
        #  track of some global totals.
        #
        @timeslots.each do |ts|
          ts.calculate(joiners_by_event_id, elements_by_commitment_id) 
        end
        #
        #  For each resource, which has slot gives the highest loading?
        #  Now we are preparing data which we may well be asked for
        #  later.
        #
        requestees.each do |requestee|
          max_loading = Loading::NoLoading
          max_loading_slot = nil
          @timeslots.each do |ts|
            if requestee.overall
              new_loading = ts.summary_loading
            else
              new_loading = ts.loading_for(requestee)
            end
            if new_loading.overload?
              @overloads << LoadingReport.new(requestee.entity_name,
                                              requestee.entity.element,
                                              new_loading,
                                              ts)
            end
            if new_loading > max_loading
              max_loading = new_loading
              max_loading_slot = ts
            end
          end
          if max_loading_slot && max_loading.used > 0
            @maximum_loading_reports <<
              LoadingReport.new(requestee.entity_name,
                                requestee.entity.element,
                                max_loading,
                                max_loading_slot.timing)
            #puts "Maximum loading for #{requestee.entity.name} is #{max_loading.to_s} at #{max_loading_slot.to_s}"
          end
        end
      end
    end

    def to_partial_path
      'day_loading'
    end
  end

  def initialize(element)
    #
    #  The element is the thing for which we're going to calculate
    #  resource loading.
    #
    #  Not much else we can do at this stage because we need a date
    #  in order to decide on group membership.
    #
    @element = element
  end

  #
  #  Calculate the loading for our resource on the indicated day.
  #
  def loading_on(date)
    return DayLoading.new(@element, date)
  end

  def self.count_overloads(day_loadings)
    #
    #  Given an array of day loadings, count the number of overloads.
    #
    day_loadings.inject(0) { |sum, dl| sum + dl.overloads.size }
  end

end

