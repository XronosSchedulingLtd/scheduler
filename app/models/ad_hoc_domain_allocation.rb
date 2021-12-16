#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainAllocation < ApplicationRecord

  attr_accessor :sundate

  belongs_to :ad_hoc_domain_cycle

  validates :name, presence: true

  serialize :allocations, Hash

  serialize :scores, Hash

  def as_json(options = {})
    Rails.logger.debug("Entering as_json")
    threshold = ad_hoc_domain_cycle.ad_hoc_domain.missable_threshold
    result = {
      id:   self.id,
      name: self.name,
      starts: ad_hoc_domain_cycle.starts_on.iso8601,
      ends: ad_hoc_domain_cycle.exclusive_end_date.iso8601
    }
    Rails.logger.debug("Result so far: #{result.inspect}")
    if options[:ad_hoc_domain_staff_id] &&
      staff = AdHocDomainStaff.find_by(id: options[:ad_hoc_domain_staff_id])
      result[:staff_id] = staff.id
      pcs = []
      known_pcids = []
      staff.ad_hoc_domain_pupil_courses.each do |pupil_course|
        pc = {
          pcid: pupil_course.id,
          pupil_id: pupil_course.pupil_id,
          mins: pupil_course.minutes,
          name: pupil_course.pupil.name,
          subject: pupil_course.ad_hoc_domain_subject.subject_name,
          #
          #  cm stands for Can Miss (Academic Lessons)
          #
          cm: (threshold == 0 || pupil_course.pupil.year_group < threshold)
        }
        pcs << pc
        known_pcids << pupil_course.id
      end
      #
      #  When is this member of staff available?
      #
      availables = []
      if staff.rota_template
        #
        #  Provide an array of skeletal events to provide background
        #  info.  Each needs just day of week, start time, end time.
        #
        0.upto(6) do |i|
          staff.rota_template.slots_for(i) do |rs|
            slot = Hash.new
            slot[:wday] = i
            slot[:starts_at] = rs.starts_at
            slot[:ends_at]   = rs.ends_at
            availables << slot
          end
        end
      end
      result[:availables] = availables
      result[:weeks] =
        WeekIdentifier.new(ad_hoc_domain_cycle.starts_on,
                           ad_hoc_domain_cycle.ends_on).dates
      result[:pcs] = pcs
      #
      #  It is possible that there are orphaned allocations in our
      #  list belonging to pupil courses which have been deleted.  It's
      #  important that we don't send down an inconsistent data set,
      #  so filter them now.
      #
      #  Note the use of the safe navigation operator so that the
      #  first time we go for a particular staff id we don't try to
      #  invoke select() on nil
      #
      result[:allocated] =
        self.allocations[staff.id]&.
             select {|alloc| known_pcids.include? alloc[:pcid]} || []
      #
      #  Need to get the timetable for each pupil.  Note that there
      #  may be two pupil courses for a single pupil.  Need send only
      #  one copy of his or her timetable.
      #
      categories = [
        Eventcategory.cached_category("Lesson")&.id,
        Eventcategory.cached_category("Other half")&.id
      ].compact
      timetables = Hash.new
      subjects = Hash.new
      pupil_ids = staff.ad_hoc_domain_pupil_courses.collect(&:pupil_id).uniq
      pupils = Pupil.includes(:element).where(id: pupil_ids)
      pupils.each do |pupil|
        timetables[pupil.id], tmpsubjects =
          Rails.cache.fetch("pupil#{pupil.id}tt",
                            expires_in: 6.hours,
                            race_condition_ttl: 10.seconds) do
          timetable = Hash.new
          innersubjects = Hash.new
          ea = Timetable::EventAssembler.new(pupil.element, Date.today, true)
          ea.events_by_day do |week, day_no, event|
            if categories.include?(event.eventcategory_id)
              timetable[week] ||= Array.new
              timetable[week][day_no] ||= Array.new
              subject = event.subject
              if subject
                innersubjects[subject.id] ||= subject.name
                subject_id = subject.id
                missable = subject.missable ? 1 : 0
              else
                subject_id = 0
                missable = 1
              end
              entry = {
                b: event.starts_at.to_s(:hhmm),
                e: event.ends_at.to_s(:hhmm),
                s: subject_id,
                m: missable
              }
              if subject_id == 0
                entry[:body] = event.body
              end
              timetable[week][day_no] << entry
            end
          end
          #
          #  This is what our block returns and what potentially gets cached.
          #
          [timetable, innersubjects]
        end
        subjects.merge!(tmpsubjects)
      end
      result[:timetables] = timetables
      result[:subjects] = subjects
      #
      #  Now for each referenced pupil, we need to look and see if they
      #  have any other allocations for lessons with other peri
      #  teachers.
      #
      #  For each pupil, start by seeing whether they have any
      #  PupilCourses in this AdHocDomainCycle with different teachers.
      #
      #  Might as well load the pupil courses just once, rather than
      #  once for each pupil.
      #
      all_pupil_courses =
        ad_hoc_domain_cycle.ad_hoc_domain_pupil_courses.
                            includes(:ad_hoc_domain_subject_staff).
                            to_a
      #
      other_allocated = Hash.new
      pupil_ids.each do |pid|
        other_pupil_courses =
          all_pupil_courses.select {|pc|
            pc.pupil_id == pid &&
              pc.ad_hoc_domain_subject_staff.ad_hoc_domain_staff_id != staff.id
        }
        unless other_pupil_courses.empty?
          #
          #  This pupil has other pupil courses - with staff members
          #  other than this one.  Are there any corresponding allocations?
          #
          other_allocations = []
          other_pupil_courses.each do |pc|
            staff_allocations = self.allocations[
              pc.ad_hoc_domain_subject_staff.ad_hoc_domain_staff_id]
            if staff_allocations
              relevant_allocations =
                staff_allocations.select {|al|
                  al[:pcid] == pc.id
              }
              unless relevant_allocations.empty?
                #
                #  Found some!
                #
                other_allocations += relevant_allocations
              end
            end
          end
          unless other_allocations.empty?
            other_allocated[pid] = other_allocations
          end
        end
      end
      result[:other_allocated] = other_allocated
      #
      #  And now we need to get any existing commitments for this teacher,
      #  other than those generated by us.  We don't expect him or her
      #  to have a full timetable, but there may be individual other
      #  things which he or she is doing - like taking a choral group
      #  or something like that.
      #
      our_source_id = ad_hoc_domain_cycle.ad_hoc_domain.eventsource_id
      raw_events =
        staff.staff.element.events_on(
          ad_hoc_domain_cycle.starts_on,
          ad_hoc_domain_cycle.ends_on,
          Eventcategory.busy_categories).
          select {
            |e| e.eventsource_id != our_source_id
          }
      events = raw_events.collect {|re|
        {
          body: re.body,
          starts_at: re.starts_at_for_fc,
          ends_at: re.ends_at_for_fc
        }
      }
      result[:events] = events
      result[:current] = 0
    end
    Rails.logger.debug("Leaving as_json")
    result
  end

  def update_allocations(ad_hoc_domain_staff, allocations)
    #
    #  What arrives from Rails is an array of HashWithIndifferentAccess.
    #  Whilst we can save this to the database it's inefficient, and
    #  I'd like to standardize on using just symbols.  Hence, convert it.
    #
    self.allocations[ad_hoc_domain_staff.id] =
      allocations.collect {|e| e.to_hash.symbolize_keys}
    self.save   # And return result
  end

  def parameters=(value)
    Rails.logger.debug("Allocation of parameters")
    Rails.logger.debug(value.inspect)
  end

  #
  #  Calculate the percentage completeness for either the whole allocation
  #  or just one member of staff.
  #
  #  Return a float, which may be Infinity.
  #
  def percentage_complete(ad_hoc_domain_staff = nil)
    num_weeks = self.ad_hoc_domain_cycle.num_weeks
    if ad_hoc_domain_staff
      #
      #  Just one.
      #
      #  How many lessons does this staff member need to have
      #  in the cycle?
      #
      lessons_per_cycle = ad_hoc_domain_staff.num_real_pupils * num_weeks
      #
      #  How many have been allocated?  Could be no entry at all.
      #
      entries = self.allocations[ad_hoc_domain_staff.id]
      if entries
        num_allocated = entries.size
      else
        num_allocated = 0
      end
    else
      #
      #  The lot.  We can't just iterate through our allocations
      #  because there could be a member of staff with none allocated
      #  yet.
      #
      lessons_per_cycle = 0
      num_allocated = 0
      self.ad_hoc_domain_cycle.ad_hoc_domain_staffs.each do |ad_hoc_domain_staff|
        lessons_per_cycle += (ad_hoc_domain_staff.num_real_pupils * num_weeks)
        entries = self.allocations[ad_hoc_domain_staff.id]
        if entries
          num_allocated += entries.size
        end
      end
    end
    num_allocated.to_f / lessons_per_cycle.to_f
  end

end
