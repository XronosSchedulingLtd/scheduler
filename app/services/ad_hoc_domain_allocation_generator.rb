#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainAllocationGenerator

  class OneEntry
    #
    #  And object to hold all the details for one entry to be put
    #  into the schedule.
    #
    #  Note we do not cope with all day events.
    #
    def initialize(generator, instance, pc, things = [])
      @generator = generator
      @pc = pc
      @starts_at = Time.zone.parse(instance[:starts_at])
      @ends_at   = Time.zone.parse(instance[:ends_at])
      #
      #  This will be an array of element ids.
      #
      @element_ids = Array.new
      unless things.empty?
        things.each do |thing|
          self.add_resource(thing)
        end
      end
    end

    def pcid
      @pc.id
    end

    def add_resource(thing)
      if thing.instance_of?(Element)
        element_id = thing.id
      elsif thing.respond_to?(:element)
        element_id = thing.element.id
      else
        raise "Unsuitable thing - #{thing.class}"
      end
      @element_ids << element_id
    end

    def body
      "#{@pc.pupil.name} - #{@pc.ad_hoc_domain_subject.subject_name}"
    end

    #
    #  Create a new event to match this allocation.
    #
    def create
      event = @generator.ad_hoc_domain.eventsource.events.create({
        body: self.body,
        eventcategory: @generator.ad_hoc_domain.eventcategory,
        starts_at: @starts_at,
        ends_at: @ends_at,
        all_day: false,
        source_id: self.pcid
      })
      @generator.event_created
      return event
    end

    def ensure_details(event)
      #
      #  Make sure timings and body text are correct.
      #
      do_save = false
      if event.body != self.body
        event.body = self.body
        do_save = true
      end
      if event.starts_at != @starts_at
        event.starts_at = @starts_at
        do_save = true
      end
      if event.ends_at != @ends_at
        event.ends_at = @ends_at
        do_save = true
      end
      if do_save
        @generator.event_amended
        event.save
      end
    end

    def ensure_resources(event, brand_new)
      amended = false
      existing = event.commitments.to_a
      @element_ids.each do |eid|
        commitment = existing.detect {|c| c.element_id == eid}
        if commitment
          existing.delete(commitment)
        else
          #
          #  Need to create one.
          #
          event.commitments.create({ element_id: eid })
          amended = true
        end
      end
      existing.each do |c|
        c.destroy
        amended = true
      end
      if amended && !brand_new
        @generator.event_amended
      end
    end

  end

  attr_reader :ad_hoc_domain_allocation,
              :ad_hoc_domain_cycle,
              :ad_hoc_domain,
              :events_created,
              :events_deleted,
              :events_amended

  def initialize(ad_hoc_domain_allocation)
    @ad_hoc_domain_allocation = ad_hoc_domain_allocation
    @ad_hoc_domain_cycle = @ad_hoc_domain_allocation.ad_hoc_domain_cycle
    @ad_hoc_domain = @ad_hoc_domain_cycle.ad_hoc_domain
    expand_allocations
    @events_created = 0
    @events_deleted = 0
    @events_amended = 0
  end

  def generate
    #
    #  Need to assemble all our allocations, then work through the dates
    #  specified in the ad_hoc_domain_cycle.
    #
    #
    date = @ad_hoc_domain_cycle.starts_on
    while date < @ad_hoc_domain_cycle.exclusive_end_date
      #
      #  Process one day.
      #
      allocations = @by_date[date] || []
      existing = @ad_hoc_domain.eventsource.events.on(date).to_a
      #
      #  Make sure each required one exists.
      #
      allocations.each do |allocation|
        brand_new = false
        event = existing.detect {|e| e.source_id == allocation.pcid}
        if (event)
          #
          #  Remove from array of existing so it doesn't get deleted.
          #  Note that this call does not delete the event - it just
          #  removes it from the array.
          #
          existing.delete(event)
          #
          #  Make sure timing and text is right
          #
          allocation.ensure_details(event)
        else
          #
          #  Create it
          #
          event = allocation.create
          brand_new = true
        end
        #
        #  Make sure it has the right resources.
        #
        allocation.ensure_resources(event, brand_new)
      end
      #
      #  Get rid of any spurious ones.
      #
      existing.each do |existing|
        existing.destroy
        event_deleted
      end
      #
      #  And move on to the next day.
      #
      date = date + 1.day
    end
    return true
  end

  def event_created
    @events_created += 1
  end

  def event_deleted
    @events_deleted += 1
  end

  def event_amended
    @events_amended += 1
  end

  private

  def expand_allocations
    all_allocations = @ad_hoc_domain_allocation.allocations.values.flatten
    #
    #  For speed, let's load all the AdHocDomainStaff and Staff
    #  records in one go.
    #
    #  Is this silly?  If I have 30 staff then I can either do
    #  30 + 30 database hits, or 2.  Is it worth this optimisation?
    #
    ahd_staffs =
      AdHocDomainStaff.includes([staff: :element]).
                       where(id: @ad_hoc_domain_allocation.allocations.keys)
    hashed_ahd_staffs = Hash.new
    ahd_staffs.each do |ahd_staff|
      hashed_ahd_staffs[ahd_staff.id] = ahd_staff
    end
    pcids = all_allocations.map { |a| a[:pcid] }
    ahd_pupil_courses =
      AdHocDomainPupilCourse.includes(
        [:pupil,
         [ad_hoc_domain_subject_staff: [ad_hoc_domain_subject: :subject]]]).
      where(id: pcids)
    hashed_pupil_courses = Hash.new
    ahd_pupil_courses.each do |ahd_pc|
      hashed_pupil_courses[ahd_pc.id] = ahd_pc
    end

    @by_date = Hash.new

    #
    #  Now build a collection of allocations with all the info
    #  needed and indexed by date.
    #
    @ad_hoc_domain_allocation.allocations.each do |key, instances|
      #
      #  The key is the id of an AdHocDomainStaff record.
      #  Each instance contains a pcid which is the id of an
      #  AdHocDomainPupilCourse record.
      #
      ahd_staff = hashed_ahd_staffs[key]
      if ahd_staff
        instances.each do |instance|
          pc = hashed_pupil_courses[instance[:pcid]]
          if pc
            date = Time.zone.parse(instance[:starts_at]).to_date
            entry = OneEntry.new(self, instance, pc)
            entry.add_resource(ahd_staff.staff)
            entry.add_resource(pc.pupil)
            if @ad_hoc_domain.connected_property
              entry.add_resource(@ad_hoc_domain.connected_property)
            end
            (@by_date[date] ||= Array.new) << entry
          end
        end
      end
    end
  end

end
