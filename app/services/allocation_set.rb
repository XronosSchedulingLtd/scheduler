#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  An object which holds a set of lesson allocations for a single teacher
#  in a single cycle.
#
#  Exists primarily to create itself from JSON, and turn itself back
#  into JSON.
#

class AllocationSet

  class OneAllocation
    attr_reader :pcid, :starts_at, :ends_at, :time_slot

    def initialize(starts_at, ends_at, pcid)
      @starts_at = starts_at
      @ends_at   = ends_at
      @pcid      = pcid
      @time_slot = TimeSlot.new(@starts_at.to_s(:hhmm), @ends_at.to_s(:hhmm))
      #
      #  An array of subject ids with which this allocation clashes.
      #
      @clashes = []
    end

    def date
      @starts_at.to_date
    end

    def reset_clashes
      @clashes = []
    end

    def note_clashing_subject(subject_id)
      @clashes << subject_id
    end

    #
    #  Behave a bit like a hash.
    #
    def [](key)
      case key
      when :pcid
        @pcid
      when :clashes
        @clashes
      else
        nil
      end
    end

  end

  def initialize(staff, existing_allocations, start_sunday)
    @staff = staff
    @original_allocations = existing_allocations
    @start_sunday = start_sunday
    #
    #  We want a simple array of allocations, and then two hashes - one
    #  indexed by week number and one by date.
    #
    @allocations = []
    @by_week = {}
    @by_date = {}
    @original_allocations.each do |allocation|
      if (allocation[:starts_at].is_a? String) &&
         (allocation[:ends_at].is_a? String)
        starts_at = Time.zone.parse(allocation[:starts_at])
        ends_at = Time.zone.parse(allocation[:ends_at])
        #
        #  If a string is invalid as a time, the parser returns nil.
        #
        if starts_at && ends_at
          self << OneAllocation.new(Time.zone.parse(allocation[:starts_at]),
                                    Time.zone.parse(allocation[:ends_at]),
                                    allocation[:pcid])
        end
      end
    end
  end

  def <<(allocation)
    raise "Must be passed an AllocationSet::OneAllocation" unless allocation.is_a? OneAllocation
    @allocations << allocation
    date = allocation.date
    if @by_date[date]
      @by_date[date] << allocation
    else
      @by_date[date] = [allocation]
    end
    week_no = week_of(date)
    if @by_week[week_no]
      @by_week[week_no] << allocation
    else
      @by_week[week_no] = [allocation]
    end
  end

  def add(starts_at, ends_at, pcid)
    self << OneAllocation.new(starts_at, ends_at, pcid)
  end

  def allocations_on(date)
    #
    #  Return all allocations on the given date, or an empty array if
    #  not found.
    #
    @by_date[date] || []
  end

  def allocations_in_week(week_no_or_date)
    if week_no_or_date.instance_of? Date
      week_no = week_of(week_no_or_date)
    else
      week_no = week_no_or_date
    end
    #
    #  Return all allocations in the given week, or an empty array if
    #  none found.
    #
    @by_week[week_no] || []
  end

  def as_json(options = {})
    @allocations.collect { |a|
      {
        starts_at: a.starts_at,
        ends_at: a.ends_at,
        pcid: a.pcid
      }
    }
  end

  #
  #  In which week number of our cycle does this date occur?  Weeks are
  #  numbered from 0.  Mostly we use this ourselves, but we make it
  #  available to clients too.
  #
  def week_of(date)
    #
    #  Force integer arithmetic.
    #
    (date - @start_sunday).to_i / 7
  end

  def each
    @allocations.each do |allocation|
      yield allocation
    end
  end

  def collect
    result = []
    @allocations.each do |allocation|
      hash = {
        starts_at: allocation.starts_at.gmtime.strftime("%Y-%m-%dT%H:%MZ"),
        ends_at: allocation.ends_at.gmtime.strftime("%Y-%m-%dT%H:%MZ"),
        pcid: allocation.pcid
      }
      value = yield hash
      result << value
    end
    result
  end

  def for_pupil_course(pcid)
    #
    #  Return all the allocations for the indicated pupil course.
    #
    @allocations.select {|a| a.pcid == pcid}
  end

end
