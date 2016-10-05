class MIS_PeriodTime
  attr_reader :starts_at, :ends_at, :ls_starts_at, :ls_ends_at

  #
  #  The MIS is responsible for providing the above, in a textual
  #  form like this:
  #
  #  "09:03"
  #  "12:27"
  #
  #  etc.  Note that they are always 5 characters long.
  #
end

class MIS_ScheduleEntry

  attr_reader :dbrecord, :groups, :staff, :rooms, :pupils, :period

  def initialize
    #
    #  We create these (assuming the sub-class remembers to call super())
    #  but it's up to sub-classes to populate them.
    #
    @groups = Array.new
    @staff  = Array.new
    @rooms  = Array.new
    @pupils = Array.new
  end

  def note_hiatuses(loader, hiatuses)
    #
    #  Are there any suspensions which might apply to this lesson?
    #
    @gaps, @suspensions =
      hiatuses.select { |hiatus|
        hiatus.applies_to_year?(self.yeargroup)
      }.partition { |hiatus|
        hiatus.hard?
      }
  end

  #
  #  Note that subjects are being taught, by whom and to whom.
  #
  def note_subjects_taught
    self.groups.each do |group|
      #
      #  Some are teaching groups and some are tutor groups.  The latter
      #  don't understand the concept of subject.
      #
      if group.respond_to?(:subject) && group.subject
        group.subject.note_lesson(self.staff, group)
      elsif self.respond_to?(:subject) && self.subject
        self.subject.note_lesson(self.staff, group)
      end
    end
  end

  #
  #  Note which teachers teach which groups.  At this point we're merely
  #  telling our group(s) which teacher(s) teach them.
  #
  #  Not all groups are interested, so check whether they have a suitable
  #  method.
  #
  def note_groups_taught
    self.groups.each do |group|
      if group.respond_to?(:note_teacher)
        group.note_teacher(self.staff)
      end
    end
  end

  def exists_on?(date)
    if @gaps
      @gaps.detect {|gap| gap.applies_to_lesson?(date, self.period_time)} == nil
    else
      true
    end
  end

  def suspended_on?(date)
    if @suspensions
      @suspensions.detect {|s| s.applies_to_lesson?(date, self.period_time)} != nil
    else
      false
    end
  end

  #
  #  The job of this function is to ensure that an appropriate
  #  matching database entry exists with the right time.  We either
  #  find an existing one on the indicated date (adjusting the time
  #  if necessary) or create one.  Either way, we end up with an
  #  @dbrecord instance variable pointing to it.
  #
  #  It should also do things like lesson suspensions, checking
  #  categories, lesson name etc (see importsb.rb for missing functionality)
  #  but that is still to be added.
  #
  def ensure_db(date, event_source, verbose = false)
    created_count = 0
    amended_count = 0
    period_time = self.period_time
    starts_at = Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
    ends_at   = Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
    @dbrecord =
      Event.events_on(
        date,          # Start date
        nil,           # End date
        nil,           # Categories
        @event_source, # Event source
        nil,           # Resource
        nil,           # Owner
        true           # And non-existent
      ).source_hash(self.source_hash).take
    if @dbrecord
      #
      #  Need to make sure other things about it are correct.
      #
      changed = false
      if @dbrecord.starts_at != starts_at
        puts "Start time for #{self.body_text} changed from #{@dbrecord.starts_at} to #{starts_at}." if verbose
        @dbrecord.starts_at = starts_at
        changed = true
      end
      if @dbrecord.ends_at != ends_at
        puts "End time for #{self.body_text} changed from #{@dbrecord.ends_at} to #{ends_at}." if verbose
        @dbrecord.ends_at = ends_at
        changed = true
      end
      if @dbrecord.non_existent != self.suspended_on?(date)
        puts "Suspension state for #{self.body_text} at #{@dbrecord.starts_at} changed from #{@dbrecord.non_existent} to #{self.suspended_on?(date)}." if verbose
        @dbrecord.non_existent = self.suspended_on?(date)
        changed = true
      end
      if @dbrecord.body != self.body_text
        puts "Name changed from #{@dbrecord.body} to #{self.body_text}." if verbose
        @dbrecord.body = self.body_text
        changed = true
      end
      if @dbrecord.eventcategory != self.eventcategory
        @dbrecord.eventcategory = self.eventcategory
        changed = true
      end
      if changed
        if @dbrecord.save
          #
          #  Incremement counter
          #
          @dbrecord.reload
          amended_count += 1
        else
          puts "Failed to save amended event record."
        end
      end
    else
      event = Event.new
      event.body          = self.body_text
      event.eventcategory = self.eventcategory
      event.eventsource   = event_source
      event.starts_at     = starts_at
      event.ends_at       = ends_at
      event.approximate   = false
      event.non_existent  = self.suspended_on?(date)
      event.private       = false
      event.all_day       = false
      event.compound      = true
      event.source_hash   = self.source_hash
      if event.save
        event.reload
        @dbrecord = event
        created_count += 1
      else
        puts "Failed to save event #{event.body}"
        event.errors.messages.each do |key, msgs|
          puts "#{key}: #{msgs.join(",")}"
        end
      end
    end
    [created_count, amended_count]
  end

  def ensure_resources
    raise "Can't ensure resources without a dbrecord." unless @dbrecord
    changed = false
    resources_added_count = 0
    resources_removed_count = 0
    #
    #  We use our d/b element ids
    #  as unique identifiers.
    #
    mis_element_ids =
      (self.groups.collect {|g| g.element_id} +
       self.staff.collect {|s| s.element_id} +
       self.pupils.collect {|p| p.element_id} +
       self.rooms.collect {|r| r.element_id}).compact
    db_element_ids =
      @dbrecord.commitments.select {|c|
        c.element.entity_type == "Group" ||
        c.element.entity_type == "Staff" ||
        c.element.entity_type == "Pupil" ||
        c.element.entity_type == "Location" }.
        collect {|c| c.element_id}
    db_only = db_element_ids - mis_element_ids
    mis_only = mis_element_ids - db_element_ids
    mis_only.each do |misid|
      c = Commitment.new
      c.event      = @dbrecord
      c.element_id = misid
      c.save
      resources_added_count += 1
    end
    @dbrecord.reload
    if db_only.size > 0
      @dbrecord.commitments.each do |c|
        if db_only.include?(c.element_id) && !c.covering
          c.destroy
          resources_removed_count += 1
        end
      end
    end
    [resources_added_count, resources_removed_count]
  end

end

class MIS_Schedule
  def note_hiatuses(loader, hiatuses)
    @entries.each do |entry|
      entry.note_hiatuses(loader, hiatuses)
    end
  end

  def note_subjects_taught
    @entries.each do |entry|
      entry.note_subjects_taught
    end
  end

  def note_groups_taught
    @entries.each do |entry|
      entry.note_groups_taught
    end
  end

end

class MIS_Timetable

  attr_reader :schedule

  #
  #  This method goes through all the scheduled events in the timetable
  #  making a note of any hiatuses which might apply to them.
  #
  def note_hiatuses(loader, hiatuses)
    @schedule.note_hiatuses(loader, hiatuses)
  end

  def note_subjects_taught
    @schedule.note_subjects_taught
  end

  def note_groups_taught
    @schedule.note_groups_taught
  end
end
