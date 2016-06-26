class MIS_Loader

  attr_reader :verbose,
              :full_load,
              :era,
              :start_date,
              :send_emails,
              :pupils,
              :pupil_hash,
              :staff_hash,
              :secondary_staff_hash,
              :location_hash,
              :teachinggroup_hash

  def read_mis_data(options)
    #
    #  We have no idea what "whatever" is - it's just something
    #  defined by the MIS-specific components.  Could be a large
    #  data structure, or simply a file handle.
    #
    whatever = prepare(options)
    @pupils = MIS_Pupil.construct(self, whatever)
    puts "Got #{@pupils.count} pupils." if options.verbose
    @pupil_hash = Hash.new
    @pupils.each do |pupil|
      @pupil_hash[pupil.source_id] = pupil
    end
    @staff = MIS_Staff.construct(self, whatever)
    puts "Got #{@staff.count} staff." if options.verbose
    @staff_hash = Hash.new
    @secondary_staff_hash = Hash.new
    @staff.each do |staff|
      @staff_hash[staff.source_id] = staff
      #
      #  iSAMS's API is a bit brain-dead, in that sometimes they refer
      #  to staff by their ID, and sometimes by what they call a UserCode
      #
      #  The UserCode seems to be being phased out (marked as legacy on
      #  form records), but on lessons at least it is currently the
      #  only way to find the relevant staff member.
      #
      @secondary_staff_hash[staff.secondary_key] = staff
    end
    @locations = MIS_Location.construct(self, whatever)
    @location_hash = Hash.new
    @locations.each do |location|
      @location_hash[location.source_id] = location
    end
    @tutorgroups = MIS_Tutorgroup.construct(self, whatever)
    puts "Got #{@tutorgroups.count} tutorgroups." if options.verbose
    @teachinggroups = MIS_Teachinggroup.construct(self, whatever)
    puts "Got #{@teachinggroups.count} teaching groups." if options.verbose
    @teachinggroup_hash = Hash.new
    @teachinggroups.each do |tg|
      @teachinggroup_hash[tg.source_id] = tg
    end
    @timetable = MIS_Timetable.new(self, whatever)
    puts "Got #{@timetable.entry_count} timetable entries." if options.verbose
    @event_source = Eventsource.find_by(name: Setting.current_mis)
    if @event_source
      puts "Current MIS is #{@event_source.name}"
    else
      raise "Can't find current MIS (#{Setting.current_mis}) as an event source."
    end
  end

  def initialize(options)
    @verbose     = options.verbose
    @full_load   = options.full_load
    @send_emails = options.send_emails
    if options.era
      @era = Era.find_by_name(options.era)
      raise "Era #{options.era} not found in d/b." unless @era
    else
      @era = Setting.current_era
      raise "Current era not set." unless @era
    end
    raise "Perpetual era not set." unless Setting.perpetual_era
    #
    #  If an explicit date has been specified then we use that.
    #  Otherwise, if a full load has been specified then we use
    #  the start date of the era.
    #  Otherwise, we use either today's date, or the start date of
    #  the era, whichever is the later.
    #
    if options.start_date
      @start_date = options.start_date
    elsif @full_load || Date.today < @era.starts_on
      @start_date = @era.starts_on
    else
      @start_date = Date.today
    end
    read_mis_data(options)
    yield self if block_given?
  end

  def do_staff
    staff_changed_count   = 0
    staff_unchanged_count = 0
    staff_loaded_count    = 0
    staff_deleted_count   = 0
    @staff.each do |s|
      dbrecord = s.dbrecord
      if dbrecord
        #
        #  Staff record already exists.  Any changes?
        #
        if s.check_and_update
          staff_changed_count += 1
        else
          staff_unchanged_count += 1
        end
      else
        #
        #  d/b record does not yet exist.
        #
        if s.save_to_db
          staff_loaded_count += 1
        end
      end
    end
    #
    #  Any there who shouldn't be there?
    #
    Staff.all.each do |dbrecord|
      if dbrecord.source_id && (dbrecord.source_id != 0)
        unless @staff_hash[dbrecord.source_id]
          #
          #  A member of staff seems to have gone away from SB.  This
          #  shouldn't really happen, but it seems it sometimes does.
          #
          #  My approach is to delete them *only* if there is no ancillary
          #  information.
          #
          if dbrecord.element &&
             (dbrecord.element.memberships.count > 0 ||
              dbrecord.element.commitments.count > 0)
            #
            #  Useful information about this staff member which should
            #  be kept.
            #
            if dbrecord.current
              puts "Marking #{dbrecord.name} no longer current."
              dbrecord.current = false
              dbrecord.save
              staff_changed_count += 1
            end
          else
            puts "Deleting #{dbrecord.name}"
            dbrecord.destroy
            staff_deleted_count += 1
          end
        end
      end
    end
    if @verbose || staff_changed_count > 0
      puts "#{staff_changed_count} staff record(s) amended."
    end
    if @verbose || staff_loaded_count > 0
      puts "#{staff_loaded_count} staff record(s) created."
    end
    if @verbose
      puts "#{staff_unchanged_count} staff record(s) untouched."
    end
    if @verbose || staff_deleted_count > 0
      puts "#{staff_deleted_count} staff record(s) deleted."
    end
  end

  #
  #  Compare our list of pupils read from iSAMS with those currently
  #  held in Scheduler.  Update as appropriate.
  #
  def do_pupils
    pupils_changed_count   = 0
    pupils_unchanged_count = 0
    pupils_loaded_count    = 0
    original_pupil_count = Pupil.current.count
    @pupils.each do |pupil|
      dbrecord = pupil.dbrecord
      if dbrecord
        unless dbrecord.current
          puts "Pupil #{dbrecord.name} does not seem to be current."
        end
        if pupil.check_and_update({start_year: pupil.effective_start_year(@era)})
          pupils_changed_count += 1
        else
          pupils_unchanged_count += 1
        end
      else
        if pupil.save_to_db({start_year: pupil.effective_start_year(@era)})
          pupils_loaded_count += 1
        end
      end
    end
    #
    #  Need to check for pupils who have now left.
    #
    pupils_left_count = 0
    Pupil.current.each do |dbpupil|
      pupil = @pupil_hash[dbpupil.source_id]
      unless pupil && dbpupil.datasource_id == pupil.datasource_id
        dbpupil.current = false
        dbpupil.save!
        pupils_left_count += 1
      end
    end
    final_pupil_count = Pupil.current.count
    if @verbose || pupils_changed_count > 0
      puts "#{pupils_changed_count} pupil record(s) amended."
    end
    if @verbose || pupils_loaded_count > 0
      puts "#{pupils_loaded_count} pupil record(s) created."
    end
    if @verbose || pupils_left_count > 0
      puts "#{pupils_left_count} pupil record(s) marked as left."
    end
    if @verbose
      puts "#{pupils_unchanged_count} pupil record(s) untouched."
    end
    if @verbose || original_pupil_count != final_pupil_count
      puts "Started with #{original_pupil_count} current pupils and finished with #{final_pupil_count}."
    end
  end

  def do_locations
    locations_loaded_count    = 0
    locations_changed_count   = 0
    locations_unchanged_count = 0
    @locations.each do |location|
      dbrecord = location.dbrecord
      if dbrecord
        if location.check_and_update
          locations_changed_count += 1
        else
          locations_unchanged_count += 1
        end
      else
        if location.save_to_db
          locations_loaded_count += 1
        end
      end
    end
    if @verbose || locations_loaded_count > 0
      puts "#{locations_loaded_count} location records created."
    end
    if @verbose || locations_changed_count > 0
      puts "#{locations_changed_count} location records amended."
    end
    if @verbose
      puts "#{locations_unchanged_count} location records unchanged."
    end
  end

  def do_tutorgroups
    tg_changed_count      = 0
    tg_unchanged_count    = 0
    tg_loaded_count       = 0
    tg_reincarnated_count = 0
    tgmember_removed_count   = 0
    tgmember_unchanged_count = 0
    tgmember_loaded_count    = 0
    pupils_renamed           = 0
    tg_at_start = Tutorgroup.current.count
    @tutorgroups.each do |tg|
#      puts "Processing #{tg.name}"
#      puts tg.inspect
      #
      #  There must be a more idiomatic way of doing this.
      #
      loaded,
      reincarnated,
      changed,
      unchanged,
      member_loaded,
      member_removed,
      member_unchanged = tg.ensure_db(self)
      tg_loaded_count          += loaded
      tg_reincarnated_count    += reincarnated
      tg_changed_count         += changed
      tg_unchanged_count       += unchanged
      tgmember_loaded_count    += member_loaded
      tgmember_removed_count   += member_removed
      tgmember_unchanged_count += member_unchanged
    end
    #
    #  It's possible that a tutor group has ceased to exist entirely,
    #  in which case we will still have a record in our d/b for it (possibly
    #  with members) but we need to record its demise.
    #
    tg_deleted_count = 0
    sb_tg_ids = @tutorgroups.collect { |tg| tg.dbrecord.id }.compact
    db_tg_ids = Tutorgroup.current.collect {|dbtg| dbtg.id}
    extra_ids = db_tg_ids - sb_tg_ids
    extra_ids.each do |eid|
      dbtg = Tutorgroup.find(eid)
      puts "Tutor group #{dbtg.name} exists in the d/b but not in the files." if @verbose
      #
      #  All the pupils in this group will need to have their names updated.
      #
      erstwhile_pupils =
        dbtg.members(nil, false, true).select {|member| member.class == Pupil}
      dbtg.ceases_existence(@start_date)
      erstwhile_pupils.each do |pupil|
        pupil.reload
        if pupil.element_name != pupil.element.name
          pupil.save
          pupils_renamed += 1
        end
      end
      tg_deleted_count += 1
    end
    tg_at_end = Tutorgroup.current.count
    if @verbose || tg_deleted_count > 0
      puts "#{tg_deleted_count} tutor group records deleted."
      if pupils_renamed > 0
        puts "as a result of which, #{pupils_renamed} pupils were renamed."
      end
    end
    if @verbose || tg_changed_count > 0
      puts "#{tg_changed_count} tutor group records amended."
    end
    if @verbose
      puts "#{tg_unchanged_count} tutor group records untouched."
    end
    if @verbose || tg_loaded_count > 0
      puts "#{tg_loaded_count} tutor group records created."
    end
    if @verbose || tg_reincarnated_count > 0
      puts "#{tg_reincarnated_count} tutor group records reincarnated."
    end
    if @verbose || tgmember_removed_count > 0
      puts "Removed #{tgmember_removed_count} pupils from tutor groups."
    end
    if @verbose
      puts "Left #{tgmember_unchanged_count} pupils where they were."
    end
    if @verbose || tgmember_loaded_count > 0
      puts "Added #{tgmember_loaded_count} pupils to tutor groups."
    end
    if @verbose || tg_at_start != tg_at_end
      puts "Started with #{tg_at_start} tutor groups and finished with #{tg_at_end}."
    end
  end

  def do_teachinggroups
    tg_changed_count      = 0
    tg_unchanged_count    = 0
    tg_loaded_count       = 0
    tg_reincarnated_count = 0
    tgmember_removed_count   = 0
    tgmember_unchanged_count = 0
    tgmember_loaded_count    = 0
    tg_at_start = Teachinggroup.current.count
    @teachinggroups.each do |tg|
#      puts "Processing #{tg.name}"
#      puts tg.inspect
      #
      #  There must be a more idiomatic way of doing this.
      #
      loaded,
      reincarnated,
      changed,
      unchanged,
      member_loaded,
      member_removed,
      member_unchanged = tg.ensure_db(self)
      tg_loaded_count          += loaded
      tg_reincarnated_count    += reincarnated
      tg_changed_count         += changed
      tg_unchanged_count       += unchanged
      tgmember_loaded_count    += member_loaded
      tgmember_removed_count   += member_removed
      tgmember_unchanged_count += member_unchanged
    end
    #
    #  It's possible that a teaching group has ceased to exist entirely,
    #  in which case we will still have a record in our d/b for it (possibly
    #  with members) but we need to record its demise.
    #
    tg_deleted_count = 0
    sb_tg_ids = @teachinggroups.collect { |tg| tg.dbrecord.id }.compact
    db_tg_ids = Teachinggroup.current.collect {|dbtg| dbtg.id}
    extra_ids = db_tg_ids - sb_tg_ids
    extra_ids.each do |eid|
      dbtg = Teachinggroup.find(eid)
      puts "Teaching group #{dbtg.name} exists in the d/b but not in the files." if @verbose
      dbtg.ceases_existence(@start_date)
      tg_deleted_count += 1
    end
    tg_at_end = Teachinggroup.current.count
    if @verbose || tg_deleted_count > 0
      puts "#{tg_deleted_count} teaching group records deleted."
    end
    if @verbose || tg_changed_count > 0
      puts "#{tg_changed_count} teaching group records amended."
    end
    if @verbose
      puts "#{tg_unchanged_count} teaching group records untouched."
    end
    if @verbose || tg_loaded_count > 0
      puts "#{tg_loaded_count} teaching group records created."
    end
    if @verbose || tg_reincarnated_count > 0
      puts "#{tg_reincarnated_count} teaching group records reincarnated."
    end
    if @verbose || tgmember_removed_count > 0
      puts "Removed #{tgmember_removed_count} pupils from teaching groups."
    end
    if @verbose
      puts "Left #{tgmember_unchanged_count} pupils where they were."
    end
    if @verbose || tgmember_loaded_count > 0
      puts "Added #{tgmember_loaded_count} pupils to teaching groups."
    end
    if @verbose || tg_at_start != tg_at_end
      puts "Started with #{tg_at_start} teaching groups and finished with #{tg_at_end}."
    end
  end

  def do_timetable
    puts "Loading events from #{@start_date} to #{@era.ends_on}" if @verbose
    event_created_count         = 0
    event_deleted_count         = 0
    event_amended_count         = 0
    resources_added_count       = 0
    resources_removed_count     = 0
    set_to_naming_count         = 0
    set_to_not_naming_count     = 0
    @start_date.upto(@era.ends_on) do |date|
      puts "Processing #{date}" if @verbose
      lessons = @timetable.lessons_on(date)
      if lessons
        puts "#{lessons.count} lessons for #{date.to_s}"
        lessons.each do |lesson|
          #
          #  Make sure each of these lessons exists in the d/b and
          #  at the right time.
          #
          created_count, amended_count = lesson.ensure_db(date, @event_source)
          event_created_count += created_count
          event_amended_count += amended_count
          #
          #  And the right resources?
          #
          added_count, removed_count = lesson.ensure_resources
          resources_added_count += added_count
          resources_removed_count += removed_count
        end
      else
        puts "No lessons for #{date.to_s}"
      end
if false
      if lessons
        lessons = lessons.select {|lesson| lesson.exists_on?(date)}
        lesson_hash = Hash.new
        lessons.each do |lesson|
          lesson_hash[lesson.source_hash] = lesson
        end
        dbevents = Event.events_on(date,          # Start date
                                   nil,           # End date
                                   nil,           # Categories
                                   @event_source, # Event source
                                   nil,           # Resource
                                   nil,           # Owner
                                   true)          # And non-existent
        dbhashes = dbevents.collect {|dbe| dbe.source_hash}.uniq
        mishashes = lessons.collect {|lesson| lesson.source_hash}
        puts "#{mishashes.size} events in MIS and #{dbhashes.size} in the d/b."
        #
        #  Anything in the database, but not in the MIS files?
        #
        dbonly = dbhashes - mishashes
        if dbonly.size > 0
          puts "Deleting #{dbonly.size} events." if @verbose
          #
          #  These I'm afraid have to go.  Given only the source
          #  hash we don't have enough to find the record in the d/b
          #  (because they repeat every fortnight) but happily we
          #  already have the relevant d/b record in memory.
          #
          dbonly.each do |dbo|
            dbrecord = dbevents.find {|dbe| dbe.source_hash == dbo}
            if dbrecord
              dbrecord.destroy
            end
            event_deleted_count += 1
          end
        end
        #
        #  And now anything in the MIS files which isn't in the d/b?
        #
        misonly = mishashes - dbhashes
        if misonly.size > 0
          puts "Adding #{misonly.size} events." if @verbose
          misonly.each do |miso|
            lesson = lesson_hash[miso]
            lesson.add_to_db
          end
        end
        #
        #  All the right events should now be in the database.
        #  Run through them making sure they have the right time and
        #  the right resources.
        #
        lessons.each do |lesson|
          if event = dbevents.detect {
            |dbe| dbe.source_hash == lesson.source_hash
          }
            #
            #  Now have a d/b record (event) and a SB record (lesson).
            #
            lesson.ensure_time_and_resources(event)
          else
            puts "Very odd - d/b record #{lesson.source_hash} has disappeared."
          end
        end
      else
        puts "Couldn't find lesson entries for #{date.strftime("%A")}."
      end
end
    end
    if event_created_count > 0 || @verbose
      puts "#{event_created_count} timetable events added."
    end
    if event_deleted_count > 0 || @verbose
      puts "#{event_deleted_count} timetable events deleted."
    end
    if resources_added_count > 0 || @verbose
      puts "#{resources_added_count} resources added to timetable events."
    end
    if resources_removed_count > 0 || @verbose
      puts "#{resources_removed_count} resources removed from timetable events."
    end
  end

end
