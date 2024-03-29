#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  An object which can handle auto allocation of AdHoc lessons.
#
#  Can do it for:
#
#  * One staff, one cycle, one week.
#  * One staff, one whole cycle.
#  * One whole cycle - all staff.
#

class AutoAllocator

  class Potential
    attr_reader :date, :time_slot, :cost

    #
    #  A potential slot for one student.
    #
    def initialize(date, time_slot, cost)
      @date      = date
      @time_slot = time_slot
      @cost      = cost
    end

    def dump
      Rails.logger.debug("    Cost #{@cost} at #{time_slot.to_s} on #{date}")
    end
  end

  class PupilPotentials < Array
    #
    #  An enhanced array to store all the current potential slots
    #  for one student.
    #
    attr_reader :pid, :name

    def initialize(pc)
      super()
      @pid  = pc.pupil_id
      @name = pc.name
      @lowest_cost = nil
    end

    def add_entry(date, time_slot, cost)
      if @lowest_cost.nil? || cost < @lowest_cost
        @lowest_cost = cost
      end
      self << Potential.new(date, time_slot, cost)
    end

    def count_slots_at(cost)
      self.select {|p| p.cost == cost}.count
    end

    #
    #  How many slots does this student have at his or her current
    #  lowest cost.
    #
    def count_lowest_cost_slots
      count_slots_at(@lowest_cost)
    end

    def summary
      #
      #  Return a summary hash, mimicking what we had before we created
      #  these structures.
      #
      result = Hash.new { |h,k| h[k] = Hash.new(0) }
      self.each do |potential|
        result[potential.cost] += 1
      end
      result
    end

    def best_score
      self.collect(&:cost).min
    end

    def dump
      Rails.logger.debug("  #{@pid} #{@name}")
      self.sort_by(&:cost).each do |potential|
        potential.dump
      end
    end

    def cost_of_missing(score)
      #
      #  If we miss out on a slot with the indicated score, how much
      #  worse is our next best one?
      #
      scores = self.collect(&:cost).sort
      #
      #  It's tempting to use "scores.delete" but that will take
      #  away *all* instances of the indicated score.
      #
      index = scores.index(score)
      if index
        scores.delete_at(index)
      end
      if scores.empty?
        999
      else
        #
        #  The first entry in the array is now our best score.
        #  If that's less than what we were asked about, then we
        #  will return a negative value.
        #
        scores[0] - score
      end
    end

  end

  class AllPotentials < Hash
    #
    #  All our current potentials, indexed by pupil id.
    #
    def initialize
      super()
    end

    def add_entry(pc, date, time_slot, cost)
      pupil_potentials = self[pc.pupil_id] ||= PupilPotentials.new(pc)
      pupil_potentials.add_entry(date, time_slot, cost)
    end

    def best_score_for(pid)
      pupil_potentials = self[pid]
      if pupil_potentials
        pupil_potentials.best_score
      else
        9999
      end
    end

    def cost_of_pupil_missing(pid, score)
      pupil_potentials = self[pid]
      if pupil_potentials
        pupil_potentials.cost_of_missing(score)
      else
        9999
      end
    end

    def dump
      self.each do |pid, pupil_potentials|
        pupil_potentials.dump
      end
    end

  end

  class OtherAllocations < Hash

    class OtherAllocation
      attr_reader :starts_at, :ends_at, :date, :time_slot

      def initialize(item)
        @starts_at = Time.zone.parse(item[:starts_at])
        @ends_at   = Time.zone.parse(item[:ends_at])
        @date      = @starts_at.to_date
        @time_slot = TimeSlot.new(@starts_at.to_s(:hhmm),
                                  @ends_at.to_s(:hhmm))
      end
    end

    class PupilOtherAllocations < Array
      attr_reader :pid

      #
      #  A set of other allocations for one individual pupil.
      #
      def initialize(pid, allocations)
        super()
        @pid = pid
        allocations.each do |item|
          self << OtherAllocation.new(item)
        end
      end

      def any_clashes_with?(date, time_slot)
        !self.select {|oa|
          oa.date == date &&
            oa.time_slot.overlaps?(time_slot)
        }.empty?
      end

    end

    #
    #  Record other allocations which we can't change but have to
    #  work around.
    #
    def initialize(raw_data)
      super()
      #
      #  We expect to receive a hash, indexed by pupil id.
      #
      raw_data.each do |pid, allocations|
        self[pid] = PupilOtherAllocations.new(pid, allocations)
      end
    end

  end

  class OtherEngagements < Array
    #
    #  Record other occasions when this member of staff is busy.
    #

    class OtherEngagement
      attr_reader :body, :starts_at, :ends_at, :date, :time_slot

      def initialize(item)
        @body = item[:body]
        @starts_at = Time.zone.parse(item[:starts_at])
        @ends_at   = Time.zone.parse(item[:ends_at])
        @date      = @starts_at.to_date
        @time_slot = TimeSlot.new(@starts_at.to_s(:hhmm),
                                  @ends_at.to_s(:hhmm))
      end

    end

    def initialize(items)
      super()
      items.each do |item|
        self << OtherEngagement.new(item)
      end
    end

    def on(date)
      #
      #  Return an array of OtherEngagements on a given date.
      #
      self.select {|oe| oe.date == date}
    end

  end

  class Availables < Array

    class Available
      #
      #  params should be a hash with:
      #    wday:      integer
      #    starts_at: time string
      #    ends_at:   time string
      #
      attr_reader :time_slot

      def initialize(params)
        @wday = params[:wday]
        @time_slot = TimeSlot.new(params[:starts_at], params[:ends_at])
      end

      def happens_on?(wday)
        @wday == wday
      end

      #
      #  Return this Available as a time_slot_set which the
      #  caller is then free to modify.
      #
      def slot_set
        TimeSlotSet.new(self.time_slot)
      end

    end

    def initialize(availables)
      availables.each do |available|
        self << Available.new(available)
      end
    end

    def on(date)
      wday = date.wday
      self.select {|a| a.happens_on?(wday)}
    end

    def slots_on(date)
      self.on(date).collect {|a| a.time_slot}
    end

  end

  class PupilCourses < Hash

    class PupilCourse
      attr_reader :pcid, :pupil_id, :mins, :can_miss, :name

      def initialize(raw_pc)
        @pcid =     raw_pc[:pcid]
        @pupil_id = raw_pc[:pupil_id]
        @mins =     raw_pc[:mins]
        @can_miss = raw_pc[:cm]
        @name     = raw_pc[:name]
      end

    end

    def initialize(raw_pcs)
      #
      #  We are passed the array of raw pupil courses received in our
      #  dataset.
      #
      super()
      raw_pcs.each do |raw_pc|
        pc = PupilCourse.new(raw_pc)
        self[pc.pcid] = pc
      end
    end

    def by_pcids(pcids)
      #
      #  Passed an array of pcids, return any PupilCourses in that
      #  list.
      #
      self.values.select {|pc| pcids.include?(pc.pcid)}
    end

    def except(pcids)
      #
      #  Passed an array of pcids, return any PupilCourses not in that
      #  list.
      #
      self.values.select {|pc| !pcids.include?(pc.pcid)}
    end

    def modal_lesson_length
      #
      #  Returns the modal lesson length in minutes.
      #
      #  Sadly, at the time of writing we're still using Ruby 2.6 so
      #  Enumerable#tally is not available to us.
      #
      #  Tally gives us a hash of durations and counts and then
      #  we sort to put the largest count last, select the last
      #  pair with [-1], then pick the duration with [0]
      #  
      if self.empty?
        5
      else
        self.values.collect(&:mins).tally.sort_by{|key,value| value}[-1][0]
      end
    end

    def total_duration
      #
      #  The sum of all our lesson lengths, in minutes.
      #
      self.values.collect(&:mins).sum
    end

    def slack(slots)
      #
      #  Calculate the slack given the indicated slots.
      #
      slots.collect(&:mins).sum - self.total_duration
    end

  end

  class Timetables < Hash

    class Timetable

      class OneLesson

        attr_reader :time_slot, :subject_id, :missable

        def initialize(slot)
          @time_slot = TimeSlot.new(slot[:b], slot[:e])
          @subject_id = slot[:s]
          @missable = (slot[:m] == 1)
        end
      end

      def initialize(pupil_timetable, week_identifier)
        #
        #  We are passed a raw pupil timetable, which itself should
        #  consist of two week timetables as a hash, indexed by A and B.
        #
        @week_identifier = week_identifier
        @data = pupil_timetable.transform_values do |week_timetable|
          week_timetable.collect do |day_timetable|
            if day_timetable.nil?
              nil
            else
              day_timetable.collect do |slot|
                OneLesson.new(slot)
              end
            end
          end
        end
      end

      def entries_on(date)
        week_letter = @week_identifier.week_letter(date)
        week_entries = @data[week_letter]
        if week_entries
          #
          #  Our callers always expect to get an array, even if empty.
          #
          week_entries[date.wday] || []
        else
          []
        end
      end

    end

    def initialize(raw_timetables, cycle)
      @week_identifier = WeekIdentifier.new(cycle.starts_on, cycle.ends_on)
      #
      #  We are passed a hash of raw timetables, indexed by pupil_id
      #
      super()
      raw_timetables.each do |pid, pupil_timetable|
        self[pid] = Timetable.new(pupil_timetable, @week_identifier)
      end
    end

  end

  class UnallocatedSet
    #
    #  Add some extra functions to an array of unallocated pupil courses
    #  to enable manipulation.
    #
    def initialize(loadings, pcs)
      #
      #  We will be taking things out of this array so do a shallow
      #  duplication.
      #
      @pcs = pcs.dup
      @loadings = loadings
    end

    def eliminate_over!(mins)
      @pcs = @pcs.select {|pc| pc.mins <= mins}
    end

    def eliminate_clashes!(date, time_slot)
      @pcs = @pcs.select { |pc|
        would_use = time_slot.trim_to(pc.mins.minutes)
        !@loadings.other_allocations[pc.pupil_id]&.any_clashes_with?(date,
                                                                     would_use)
      }
    end

    def eliminate_better_elsewhere!(date, time_slot)
      @pcs = @pcs.select { |pc|
        Rails.logger.debug("Considering #{pc.name}")
        @loadings.best_possible_score(pc) >=
          @loadings.cost_for(pc, date, time_slot)
      }
    end

    def select_lowest_cost!(date, time_slot)
      #
      #  Select all the pupil courses which share an equal lowest
      #  cost for this lot.  That is - work out the lowest possible
      #  cost of occupying this slot and select all the pcs which would
      #  have that cost.
      #
      lowest_cost = 999
      chosen = []
      @pcs.each do |pc|
        cost = @loadings.cost_for(pc, date, time_slot)
        if cost < lowest_cost
          #
          #  We have a new lowest cost
          #
          lowest_cost = cost
          chosen = [pc]
        elsif cost == lowest_cost
          #
          #  Add one to our selection
          #
          chosen << pc
        end
      end
      @pcs = chosen
      return lowest_cost
    end

    def select_highest_penalty_of_missing!(date, time_slot)
      #
      #  For each candidate, work out how much *more* it would cost
      #  this candidate if he or she didn't get this slot.  Select
      #  all those with highest such cost.
      #
      highest_penalty = -999
      chosen = []
      @pcs.each do |pc|
        cost = @loadings.cost_for(pc, date, time_slot)
        penalty =
          @loadings.all_potentials.cost_of_pupil_missing(pc.pupil_id, cost)
        if penalty > highest_penalty
          #
          #  We have a new highest penalty
          #
          highest_penalty = penalty
          chosen = [pc]
        elsif penalty == highest_penalty
          #
          #  Add one to our selection
          #
          chosen << pc
        end
      end
      @pcs = chosen
    end

    def select_best_for_pupil!(date, time_slot)
      #
      #  Pick all the pupil courses for which slot would be their
      #  best current option.
      #
      chosen = []
      @pcs.each do |pc|
        cost = @loadings.cost_for(pc, date, time_slot)
        if cost == @loadings.all_potentials.best_score_for(pc.pupil_id)
          chosen << pc
        end
      end
      @pcs = chosen
    end

    def least_flexible
      #
      #  Pick the unallocated pupil course which has the fewest available
      #  slots at its minimum cost.
      #
      #  This used to take a cost as an argument and calculate the
      #  fewest at that cost, but it's now more flexible.  If the
      #  set has previously been adjusted so that they all have the
      #  same lowest cost (by discarding any others) then it will work
      #  as before, but it could also be used with a more mixed set, working
      #  out which of them has the fewest at their individual lowest cost.
      #
      #  Sixth formers take priority, even if they are not the
      #  least flexible.  Once we've chosen one, only another less
      #  flexible sixth former can usurp the slot.
      #
      #  E.g. a sixth former has 3 slots with a cost of 0, whilst
      #  a middle schooler has only 1 slot with a cost of 0, but other
      #  possibilities available.
      #
      #  N.B.  "unallocated" array may be empty.
      #
      fewest = 999
      chosen = nil
      chosen_inflexible_one = false
      #
      self.each do |pc|
        #
        #  If we have already chosen an inflexible pupil and this latest
        #  one is flexible then we don't consider him or her.
        #
        unless chosen_inflexible_one && pc.can_miss
          possibilities =
            @loadings.all_potentials[pc.pupil_id].count_lowest_cost_slots
          if possibilities < fewest
            fewest = possibilities
            chosen = pc
            if !pc.can_miss
              chosen_inflexible_one = true
            end
          end
        end
      end
      chosen
    end

    def size
      @pcs.size
    end

    #
    #  Probably want to eliminate this as a public method by
    #  moving the functionality which calls it into this object
    #
    def select(&block)
      selected = @pcs.select(&block)
      UnallocatedSet.new(@loadings, selected)
    end

    #
    #  Likewise
    #
    def each
      @pcs.each do |pc|
        yield pc
      end
    end

    def empty?
      @pcs.empty?
    end

  end

  class Loadings
    attr_reader :other_allocations, :all_potentials, :loadings_by_pid

    #
    #  An object to hold a set of loadings and recalculate
    #  them on request.  To do this it needs to control both
    #  the PupilCourse and Allocated objects.
    #
    #  Note that this object is not the least bit interested in
    #  *how* to place the allocations - it just keeps track of them
    #  and calculates the results.
    #
    #  It also handles requests which involve both the PupilCourses
    #  and the existing Allocations - e.g. give me all the unallocated
    #  PupilCourses in a given week.
    #
    def initialize(pcs, allocated, other_allocations, timetables)
      #
      #  Currently pcs is a PupilCourses object whilst allocated is
      #  an AllocationSet object.
      #
      @pupil_courses     = pcs
      @allocated         = allocated
      @other_allocations = other_allocations
      @timetables        = timetables
      #
      #  Something to hold all my calculated loadings.
      #
      #  A hash indexed by pupil id and each value in that
      #  hash is itself a hash indexed by subject id.
      #
      #  Note that other half things all have a subject id of 0.  May
      #  need to implement special processing there and index by
      #  body instead.
      #
      #  Interesting oddity of default values for hashes in Ruby.
      #  See https://stackoverflow.com/questions/2698460/strange-unexpected-behavior-disappearing-changing-values-when-using-hash-defa
      #
      #  To avoid our outer hash getting the *same* hash again and again
      #  for each entry we have to construct the inner one in a block.
      #
      #  If we just write:
      #
      #    Hash.new(Hash.new(0))
      #
      #  then a single inner hash is used for all apparent entries in
      #  the outer hash - and it never gets assigned to being an entry
      #  in the outer hash.
      #
      @loadings_by_pid = Hash.new { |h,k| h[k] = Hash.new(0) }
      calculate_all
      Rails.logger.debug("Initial loadings")
      Rails.logger.debug(@loadings_by_pid.inspect)
      #
      #  Empty for now.
      #
      @all_potentials = AllPotentials.new
    end

    def allocated_in_week(date)
      #
      #  Given a single date within a week (Sun-Sat) return an
      #  array of allocated PupilCourses in that week.
      #
      allocated_pcids =
        @allocated.allocations_in_week(date).collect {|a| a.pcid}.uniq
      @pupil_courses.by_pcids(allocated_pcids)
    end

    def unallocated_in_week(date)
      #
      #  Given a single date within a week (Sun-Sat) return an
      #  array of unallocated PupilCourses in that week.
      #
      allocated_pcids =
        @allocated.allocations_in_week(date).collect {|a| a.pcid}.uniq
      UnallocatedSet.new(self, @pupil_courses.except(allocated_pcids))
    end

    def all_allocated_in_week?(date)
      unallocated_in_week(date).empty?
    end

    def add_allocation(starts_at, ends_at, pcid)
      #
      #  Passed via us so we can update our idea of the loadings.
      #
      @allocated.add(starts_at, ends_at, pcid)
      recalculate(pcid)
    end

    def best_possible_score(pc)
      #
      #  What's the best possible score for the indicated pupil
      #  course, given the current state of our @all_potentials
      #  information?
      #
      @all_potentials.best_score_for(pc.pupil_id)
    end

    def best_choice_for1(date, time_slot)
      unallocated = unallocated_in_week(date)
      #
      #  "unallocated" is the initial list of pupil courses which we
      #  might consider for this slot.  Need to score them.  Algorithm
      #  is as follows:
      #
      #  0. Eliminate any which are too big to fit here.
      #  1. Eliminate any which have a clashing other allocation.
      #  2. Calculate the cost of each in this slot.
      #  3. Take only those with the lowest cost, whatever that is.
      #  4. Eliminate all those which have a lower cost elsewhere.
      #  5. Choose the one with the lowest number of other slots
      #     with the same cost.
      #
      #  Note that we might end up eliminating everyone and thus provide
      #  no-one for this slot.  This should be dealt with later because
      #  either the unallocated will get allocated somewhere else at lower
      #  cost, or we'll come back to this slot once those lower cost
      #  points have been eliminated.
      #
      unallocated.eliminate_over!(time_slot.mins)
      #
      #  Does any student have a clashing "other commitment"?
      #
      unallocated.eliminate_clashes!(date, time_slot)
      #
      #  Now we want to select all the lowest cost ones.
      #
      #  Note here that sixth formers' academic lessons have a cost of
      #  1000, so they will never slip under the lowest_cost threshold
      #  of 999.  All sixth formers with an academic clash are thus
      #  discarded at this point.
      #
      unallocated.select_lowest_cost!(date, time_slot)
      #
      #  Could any of these do better elsewhere?
      #  Note this is not just "better in our slot", but anywhere better
      #  in the whole of what's left.
      #
      unallocated.eliminate_better_elsewhere!(date, time_slot)
      #
      #  And take the least flexible.
      #
      chosen = unallocated.least_flexible

      if chosen
        Rails.logger.debug("Chose #{chosen.name} (#{chosen.pupil_id}) at a cost of #{cost_for(chosen, date, time_slot)}")
      else
        Rails.logger.debug("Didn't pick anyone")
      end
      chosen
    end

    def best_choice_for(date, time_slot)
      unallocated = unallocated_in_week(date)
      #
      #  Uncontroversial stuff
      #
      unallocated.eliminate_over!(time_slot.mins)
      unallocated.eliminate_clashes!(date, time_slot)
      #
      #  Now a slightly different approach.
      #
      unallocated.select_best_for_pupil!(date, time_slot)
      unallocated.select_highest_penalty_of_missing!(date, time_slot)
      unallocated.select_lowest_cost!(date, time_slot)

      chosen = unallocated.least_flexible

      if chosen
        Rails.logger.debug("Chose #{chosen.name} (#{chosen.pupil_id}) at a cost of #{cost_for(chosen, date, time_slot)}")
      else
        Rails.logger.debug("Didn't pick anyone")
      end
      chosen
    end

    def calculate_potentials(all_availables, other_engagements, date_range, jump_by)
      #
      #  Work out when the teacher is available in this date range
      #
      #Rails.logger.debug("Calculating potentials")
      #
      #  Reset our accumulator.
      #
      @all_potentials = AllPotentials.new
      #
      #  Now, what pupil courses do we need to consider?
      #
      unallocated = unallocated_in_week(date_range.start_date)
      #
      #  This following loop is very similar to the one used for
      #  actual allocation, but unfortunately this needs to be
      #  done separately because we have to calculate all of
      #  these before we can do any allocation.
      #
      #  Note that we're going to consider all our unallocated
      #  pupil courses for each potential slot.
      #
      date_range.each do |date|
        isodate = date.iso8601
        availables = all_availables.on(date)
        #
        #  What time slots are available?
        #
        time_slots = TimeSlotSet.new
        availables.each do |ea|
          time_slots |= ea.slot_set
        end
        #
        #  Remove all existing allocations.
        #
        @allocated.allocations_on(date).each do |alloc|
          time_slots -= alloc.time_slot
        end
        #
        #  And other engagements for this staff member.
        #
        other_engagements.on(date).each do |oe|
          time_slots -= oe.time_slot
        end
        #
        #  
        #
        time_slots.each do |ts|
          considering = ts
          while considering
            #
            #  See whether each lesson would fit here.
            #
            unallocated.select { |pc|
              pc.mins <= considering.mins
            }.select { |pc|
              would_use = considering.trim_to(pc.mins.minutes)
              !@other_allocations[pc.pupil_id]&.any_clashes_with?(date,
                                                                  would_use)
            }.each do |pc|
              @all_potentials.add_entry(
                pc, date, considering, cost_for(pc, date, considering))
            end
            #
            #  And move on if possible.
            #
            if considering.mins > jump_by
              considering = considering.pretruncate(jump_by.minutes)
            else
              considering = nil
            end
          end
        end
      end
      #Rails.logger.debug("Potentials")
      #Rails.logger.debug(@all_potentials.inspect)
    end

    def dump_potentials
      Rails.logger.debug("Candidates:")
      @all_potentials.dump
    end

    def cost_for(pc, date, target_slot)
      #
      #  Calculate the cost for the pupil of putting an allocation for
      #  this pupil course at this proposed time.
      #
      #  Note - we don't attempt to check it fits in the indicated
      #  slot.  We use the duration of the allocation.  Calling code
      #  should have already checked whether it fits.
      #
      cost = 0
      slot = TimeSlot.new(target_slot.beginning,
                          target_slot.beginning + pc.mins.minutes)
      timetable = @timetables[pc.pupil_id]
      loadings = @loadings_by_pid[pc.pupil_id]
      if timetable
        lessons = timetable.entries_on(date)
        lessons.each do |lesson|
          if slot.overlaps?(lesson.time_slot)
            #
            #  Is this student allowed to miss this lesson?
            #
            if pc.can_miss
              #
              #  This student is allowed to miss academic lessons
              #
              cost += (loadings[lesson.subject_id] + 1)
            else
              #
              #  This student is not allowed to miss academic
              #  lessons.  Is this lesson missable?
              #
              unless lesson.missable
                cost += 1000
              end
            end
          end
        end
      end
      cost
    end

    private

    def least_flexible(unallocated, cost)
      #
      #  Pick the unallocated pupil course which has the fewest available
      #  slots at the indicated cost.
      #
      #  Sixth formers take priority, even if they are not the
      #  least flexible.  Once we've chosen one, only another less
      #  flexible sixth former can usurp the slot.
      #
      #  E.g. a sixth former has 3 slots with a cost of 0, whilst
      #  a middle schooler has only 1 slot with a cost of 0, but other
      #  possibilities available.
      #
      #  N.B.  "unallocated" array may be empty.
      #
      fewest = 999
      chosen = nil
      chosen_inflexible_one = false
      #
      #  Try sorting the candidates in a random order before selection
      #  to give everyone a chance.
      #
      #  Don't like this - it means the result is indeterminate.
      #
      #unallocated.shuffle.each do |pc|
      unallocated.each do |pc|
        #
        #  If we have already chosen an inflexible pupil and this latest
        #  one is flexible then we don't consider him or her.
        #
        unless chosen_inflexible_one && pc.can_miss
          possibilities = @all_potentials[pc.pupil_id].count_slots_at(cost)
          if possibilities < fewest
            fewest = possibilities
            chosen = pc
            if !pc.can_miss
              chosen_inflexible_one = true
            end
          end
        end
      end
      chosen
    end

    def calculate_all
      #
      #  Do a loading calculation for all the students
      #
      #  First our allocations
      #
      @allocated.each do |allocation|
        pc = @pupil_courses[allocation.pcid]
        if pc
          timetable = @timetables[pc.pupil_id]
          if timetable
            lessons = timetable.entries_on(allocation.date)
            lessons.each do |lesson|
              unless lesson.missable
                if allocation.time_slot.overlaps?(lesson.time_slot)
                  @loadings_by_pid[pc.pupil_id][lesson.subject_id] += 1
                  allocation.note_clashing_subject(lesson.subject_id)
                end
              end
            end
          end
        end
      end
      #
      #  Then all the fixed allocations.
      #
      @other_allocations.each do |pid, pupil_allocations|
        timetable = @timetables[pid]
        if timetable
          pupil_allocations.each do |allocation|
            lessons = timetable.entries_on(allocation.date)
            lessons.each do |lesson|
              unless lesson.missable
                if allocation.time_slot.overlaps?(lesson.time_slot)
                  @loadings_by_pid[pid][lesson.subject_id] += 1
                end
              end
            end
          end
        end
      end
    end

    def recalculate(pcid)
      #
      #  Recalculate the loading for one pupil, indicated by a PupilCourse id.
      #
      pc = @pupil_courses[pcid]
      if pc
        pid = pc.pupil_id
        timetable = @timetables[pid]
        if timetable
          #
          #  Expunge our previous values for this pupil.
          #
          @loadings_by_pid[pid] = Hash.new(0)
          #
          #  Dynamic allocations
          #
          @allocated.for_pupil_course(pcid).each do |allocation|
            allocation.reset_clashes
            lessons = timetable.entries_on(allocation.date)
            lessons.each do |lesson|
              unless lesson.missable
                if allocation.time_slot.overlaps?(lesson.time_slot)
                  @loadings_by_pid[pc.pupil_id][lesson.subject_id] += 1
                  allocation.note_clashing_subject(lesson.subject_id)
                end
              end
            end
          end
          #
          #  Fixed allocations
          #
          others = @other_allocations[pid]
          if others
            others.each do |allocation|
              lessons = timetable.entries_on(allocation.date)
              lessons.each do |lesson|
                unless lesson.missable
                  if allocation.time_slot.overlaps?(lesson.time_slot)
                    @loadings_by_pid[pid][lesson.subject_id] += 1
                  end
                end
              end
            end
          end
        end
      end
    end

  end

  #
  #=======================================================
  #
  #  Start of AutoAllocator proper.
  #
  #=======================================================
  #

  attr_reader :allocation_set

  #
  #  For now, require a staff member to be specified.  Later we will
  #  make the optional and do the work for the whole cycle.
  #
  #  The existing_allocations parameter is used only when working on a
  #  single member of staff.  If it's not provided then we will consult
  #  the database and fetch any which we find there.
  #
  #  Notice that passing an empty array is different from passing nil.
  #
  #  Passing nil means "Fetch from database", whilst an empty array means
  #  "start with no existing allocations".
  #
  #  Allocation is an ad_hoc_domain_allocation
  #  Staff is an ad_hoc_domain_staff
  #  Existing_allocations is an array of hashes, as received via JSON.
  #
  #  My general philosophy is to assemble all the required data - in
  #  an easy to use form - in this function, but to do all the calculations
  #  and manipulation in the do_allocate() function.
  #
  def initialize(
    allocation,
    staff,
    existing_allocations = nil,
    sundate = nil)

    @allocation = allocation
    @cycle = allocation.ad_hoc_domain_cycle
    @staff = staff
    @pid_cache = {}
    if sundate
      #
      #  To be absolutely sure that we have the date of a Sunday, we
      #  re-calculate it.
      #
      @sundate = Date.parse(sundate).sundate
    end
    #
    #  And now we need basically the same data which gets sent down
    #  as JSON to the host, only we don't want it as JSON so invoke as_json
    #  rather than to_json.
    #
    #  Note that this dataset will also include a set of existing allocations
    #  but we use that only if the existing_allocations parameter passed in
    #  was nil.
    #
    dataset = allocation.as_json({
      ad_hoc_domain_staff_id: @staff.id
    })
    #Rails.logger.debug("dataset contains:")
    #dataset.keys.each do |key|
    #  Rails.logger.debug("  #{key} (#{key.class})")
    #end
    #
    #  The dataset as we receive it contains some information which we
    #  don't need.  Pick and choose what we want to keep storing it in
    #  a form where it's easy to use subsequently, then drop the
    #  record which we received.
    #
    #  The dataset contains the following keyed fields:
    #
    #  Unwanted (there because front end needs them):
    #    id              - The id of the AdHocDomainAllocation
    #    name            - The name of the AdHocDomainAllocation
    #    staff_id        - The id of the AdHocDomainStaff record
    #    subjects        - A hash for converting Subject ids (as found
    #                      in the timetable entries) into subject names.
    #    weeks           - A hash keyed by date giving week letters
    #    current         - Always 0.  I think a hangover from using Backbone
    #
    #  Static:
    #    starts          - The start date of the cycle in ISO format
    #    ends            - The exclusive end date of the cycle in ISO format
    #    availables      - An array of slots when the staff member is available
    #    pcs             - An array of hashes, one for each
    #                      relevant AdHocDomainPupilCourse
    #    timetables      - A hash indexed by Pupil id of pupil timetables.
    #    other_allocated - A hash indexed by Pupil id of other allocations
    #                      for the indicated pupil.  These happen when the
    #                      pupil is studying an instrument with a different
    #                      teacher and has already been allocated at least
    #                      one slot with that teacher.
    #    events          - An array of other events in which this teacher
    #                      is involved and thus is not available to teach.
    #
    #  Dynamic:
    #    allocated       - An array of hashes each giving one existing
    #                      allocation, as stored in the d/b.  We may well
    #                      ignore this.
    #
    #  All the keys are symbols, not strings.  They will be strings
    #  by the time they get to the front end.
    #

    #
    #=============================================================
    #  Static stuff which we want.
    #=============================================================
    #
    #  When does our cycle start?  What is the date of the Sunday of
    #  that week?
    #
    @start_date = Date.parse(dataset[:starts])
    @start_sunday = @start_date - @start_date.wday.days
    @exclusive_end_date = Date.parse(dataset[:ends])
    #
    #  A full list of all the relevant pupil timetables has been assembled
    #  for us.  Put them into an easily accessible form.
    #
    @availables = Availables.new(dataset[:availables])
    @pupil_courses = PupilCourses.new(dataset[:pcs])
    #Rails.logger.debug("Modal lesson length is #{@pupil_courses.modal_lesson_length} minutes")
    #Rails.logger.debug("Total lesson length is #{@pupil_courses.total_duration} minutes")
    @timetables = Timetables.new(dataset[:timetables], @cycle)
    #Rails.logger.debug("Raw other allocations")
    #Rails.logger.debug(dataset[:other_allocated].inspect)
    @other_allocations =
      OtherAllocations.new(dataset[:other_allocated])
    @other_engagements = OtherEngagements.new(dataset[:events])
    #Rails.logger.debug("Staff commitments")
    #Rails.logger.debug(@other_engagements.inspect)
    #
    #=============================================================
    #  Potentially dynamic stuff.
    #=============================================================
    #
    #
    if existing_allocations.nil?
      #
      #  Fetch from the @allocation record for this staff member.
      #  If there aren't any, use an empty array.
      #
      existing_allocations = dataset[:allocated]
    end
    @allocation_set =
      AllocationSet.new(@staff, existing_allocations, @start_sunday)
    #
    #  We will also need some sort of record for calculated loadings.
    #  May create later.
    #
    @loadings =
      Loadings.new(@pupil_courses,
                   @allocation_set,
                   @other_allocations,
                   @timetables)
  end

  def do_allocation
    #
    #  First work out what are the dates of the week under current
    #  consideration.  Always Sun => Sat.
    #
    jump_by = @pupil_courses.modal_lesson_length
    if (@sundate)
      process_one_week(@sundate, jump_by)
    else
      #
      #  No date specified which means we are to process the whole term.
      #
      sundate = @start_sunday
      while sundate < @exclusive_end_date do
        process_one_week(sundate, jump_by)
        sundate += 7.days
      end
      #
      #  And now we need to save back what we've produced to the
      #  database.
      #
      #Rails.logger.debug(@allocation_set.to_json)
      #
      #  Note the use of as_json instead of to_json.  We want the
      #  structure which would be converted to json, not the json
      #  itself.
      #
      @allocation.update_allocations(@staff, @allocation_set, @loadings.loadings_by_pid)
    end
    true
  end

  private

  def process_one_week(sundate, jump_by)
    our_week = DateRange.new(sundate, 7.days)
    effective_dates = @cycle.date_range & our_week
    all_allocated = false
    if effective_dates
      Rails.logger.debug("Going to process #{effective_dates}")
      #Rails.logger.debug("Week number #{@allocation_set.week_of(effective_dates.start_date)}")
      #
      #  What availability slots does our staff member have in this
      #  date range?
      #
      Rails.logger.debug("#{@pupil_courses.size} pupil courses with #{@loadings.unallocated_in_week(@sundate).size} unallocated")
      got_something = true
      while got_something && !all_allocated do
        got_something = false
        #
        #  Initial calculation of potential student loadings
        #
        @loadings.calculate_potentials(@availables,
                                       @other_engagements,
                                       effective_dates,
                                       jump_by)
        #
        #  Now work through all our dates, trying to allocate something.
        #
        effective_dates.each do |date|
          isodate = date.iso8601
          availables = @availables.on(date)
          #
          #  What time slots are available?
          #
          time_slots = TimeSlotSet.new
          availables.each do |ea|
            time_slots |= ea.slot_set
          end
          #
          #  Remove all existing allocations.
          #
          @allocation_set.allocations_on(date).each do |alloc|
            time_slots -= alloc.time_slot
          end
          #
          #  And other engagements for this staff member.
          #
          @other_engagements.on(date).each do |oe|
            time_slots -= oe.time_slot
          end
          unless time_slots.empty?
            Rails.logger.debug("Available times on #{date}:")
            time_slots.each do |ts|
              Rails.logger.debug("  #{ts}")
            end
          end
          #
          #  Now try to fill something.
          #
          time_slots.each do |ts|
            considering = ts
            next_slot = false
            while !got_something && !next_slot && !all_allocated
              chosen = @loadings.best_choice_for(date, considering)
              if chosen
                starts_at =
                  Time.zone.parse("#{isodate} #{considering.beginning}")
                ends_at = starts_at + chosen.mins.minutes
                @loadings.add_allocation(starts_at, ends_at, chosen.pcid)
                got_something = true
                Rails.logger.debug("Added allocation")
                all_allocated = @loadings.all_allocated_in_week?(date)
              else
                #
                #  Skip forward and try again.  Give up if out of slot.
                #
                if considering.mins > jump_by
                  considering = considering.pretruncate(jump_by.minutes)
                  Rails.logger.debug("Moving forward to #{considering}")
                else
                  #
                  #  All we can do on this slot for now.
                  #  Really want a sort of double-break, but I don't think
                  #  Ruby has such a thing.
                  #
                  next_slot = true
                end
              end
            end
            #
            #  If we got something in this time slot then we need
            #  to break out in order to recalculate all the student
            #  potential loadings.
            #
            if got_something
              break
            end
          end
        end
      end
    end
  end

  def transform_timetables(timetables)
    #
    #  We are provided with all the necessary timetables as:
    #
    #  A hash, indexed by pupil id of:
    #    Hashes, indexed by week letter of:
    #      Arrays, of size 7 (Sun - Sat)
    #        Arrays of lessons each of which is a hash containing:
    #          b: Textual start time
    #          e: Textual end time
    #          s: Subject id
    #          and possibly
    #          body: Textual body of lesson
    #
    #  All that is fine, except that we'd quite like the innermost
    #  item to have a TimeSlot instead of the two textual bits.
    #
    timetables.transform_values do |pupil_timetable| 
      pupil_timetable.transform_values do |week_timetable|
        week_timetable.collect do |day_timetable|
          if day_timetable.nil?
            nil
          else
            day_timetable.collect do |slot|
              result = {
                s: slot[:s],
                ts: TimeSlot.new(slot[:b], slot[:e])
              }
              if slot[:body]
                result[:body] = slot[:body]
              end
              result
            end
          end
        end
      end
    end
  end

end
