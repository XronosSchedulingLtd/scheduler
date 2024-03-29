class MIS_Loader

  include MIS_Utils

  attr_reader :options,
              :era,
              :start_date,
              :pupils,
              :pupil_hash,
              :staff,
              :staff_hash,
              :location_hash,
              :subject_hash,
              :teachinggroup_hash,
              :ohgroups,
              :oh_groups_hash,
              :timetable,
              :event_source,
              :week_identifier

  def read_mis_data(options)
    @options = options
    #
    #  We have no idea what "whatever" is - it's just something
    #  defined by the MIS-specific components.  Could be a large
    #  data structure, or simply a file handle.
    #
    #  Some of the hashes which we're setting up here are really
    #  iSAMS-specific.  They should be moved into the isams-related
    #  files.
    #
    whatever = prepare(options)
    #
    #  Need staff before houses, to be able to find housemasters.
    #
    @staff = MIS_Staff.construct(self, whatever)
    puts "Got #{@staff.count} staff." if options.verbose
    @staff_hash = Hash.new
    @staff.each do |staff|
      @staff_hash[staff.source_id] = staff
    end
    #
    #  Need houses before pupils, to be able to link them.
    #
    @houses = MIS_House.construct(self, whatever)
    puts "Got #{@houses.count} houses." if options.verbose
    @pupils = MIS_Pupil.construct(self, whatever)
    puts "Got #{@pupils.count} pupils." if options.verbose
    @pupil_hash = Hash.new
    @pupils.each do |pupil|
      @pupil_hash[pupil.source_id] = pupil
    end
    @locations = MIS_Location.construct(self, whatever)
    @location_hash = Hash.new
    @locations.each do |location|
      @location_hash[location.source_id] = location
    end
    @subjects = MIS_Subject.construct(self, whatever)
    puts "Got #{@subjects.count} subjects." if options.verbose
    @subject_hash = Hash.new
    @subjects.each do |subject|
      @subject_hash[subject.source_id] = subject
#      puts "Got subject called \"#{subject.name}\"."
    end
    #
    #  The group code may need to consult the timetable code, so we
    #  create that object now.  It will get a later opportunity to
    #  do its own parsing, and refer back to groups.
    #
    @timetable = MIS_Timetable.new(self, whatever)
    @tutorgroups = MIS_Tutorgroup.construct(self, whatever)
    puts "Got #{@tutorgroups.count} tutorgroups." if options.verbose
    @teachinggroups = MIS_Teachinggroup.construct(self, whatever)
    puts "Got #{@teachinggroups.count} teaching groups." if options.verbose
    @teachinggroup_hash = Hash.new
    @teachinggroups.each do |tg|
      @teachinggroup_hash[tg.source_id] = tg
    end
    if options.activities
      @ohgroups = MIS_Otherhalfgroup.construct(self, whatever)
      puts "Got #{@ohgroups.count} other half groups." if options.verbose
      @oh_groups_hash = Hash.new
      @ohgroups.each do |ohg|
        @oh_groups_hash[ohg.isams_id] = ohg
      end
    end
    if self.respond_to?(:mis_specific_preparation)
      self.mis_specific_preparation(whatever)
    end
    #
    #  And now there should be enough to build the actual timetable
    #  data structures.
    #
    @timetable.build_schedule(self, whatever)
    puts "Got #{@timetable.entry_count} timetable entries." if options.verbose
    @timetable.note_hiatuses(self, @hiatuses)
    @timetable.note_subjects_taught
    @timetable.note_groups_taught
    @customgroups = MIS_Customgroup.construct(self, whatever)
    puts "Got #{@customgroups.size} custom groups." if options.verbose
    @customgroup_hash = Hash.new
    @customgroups.each do |cg|
      @customgroup_hash[cg.source_id_str] = cg
#      cg.report
    end
    if options.cover
      @covers = MIS_Cover.construct(self, whatever)
      puts "Got #{@covers.size} cover records." if options.verbose
    end
    PrepParsing::Prepper.new.process_timetable(@timetable)
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
    @week_letter_category = Eventcategory.find_by(name: "Week letter")
    raise "No category for week letters." unless @week_letter_category
    @duty_category = Eventcategory.find_by(name: "Duty")
    raise "No category for duties." unless @duty_category
    @yaml_source = Eventsource.find_by(name: "Yaml")
    raise "No event source for YAML." unless @yaml_source
    @event_source = Eventsource.find_by(name: Setting.current_mis)
    if @event_source
      puts "Current MIS is #{@event_source.name}" if @verbose
    else
      raise "Can't find current MIS (#{Setting.current_mis}) as an event source."
    end
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
    @hiatuses = Hiatus.load_hiatuses(self)
    #
    #  MIS-specific or school-specific code might find this useful.
    #
    @week_identifier = WeekIdentifier.new(@start_date, @era.ends_on)
    read_mis_data(options)
    if self.respond_to?(:local_processing)
      self.local_processing(options)
    end
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
              dbrecord.element.commitments.count > 0 ||
              dbrecord.element.concerns.count > 0)
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

  def do_subjects
    subjects_changed_count   = 0
    subjects_unchanged_count = 0
    subjects_loaded_count    = 0
    #
    #  Don't want to touch any subjects which we didn't put there in
    #  the first place.
    #
    my_current_subjects =
      Subject.where(datasource_id: MIS_Record.primary_datasource_id).
              current
    original_subject_count = my_current_subjects.count
    @subjects.each do |subject|
      dbrecord = subject.dbrecord
      if dbrecord
        unless dbrecord.current
          puts "Subject #{dbrecord.name} does not seem to be current."
        end
        if subject.check_and_update
          subjects_changed_count += 1
        else
          subjects_unchanged_count += 1
        end
        #
        #  The MIS_Record implementation of check_and_update deals
        #  only with fields within the record which have a specific
        #  value.  Need also to set up links to relevant staff.
        #
        subject.ensure_staff
      else
        if subject.save_to_db
          subjects_loaded_count += 1
          subject.ensure_staff
        end
      end
    end
    #
    #  Need to check for subjects which have been deleted.
    #
    subjects_deactivated_count = 0
    my_current_subjects.each do |dbsubject|
      subject = @subject_hash[dbsubject.source_id]
      unless subject
        dbsubject.current = false
        dbsubject.save!
        subjects_deactivated_count += 1
      end
    end
    final_subject_count =
      Subject.where(datasource_id: MIS_Record.primary_datasource_id).
        current.count
    if @verbose || subjects_changed_count > 0
      puts "#{subjects_changed_count} subject record(s) amended."
    end
    if @verbose || subjects_loaded_count > 0
      puts "#{subjects_loaded_count} subject record(s) created."
    end
    if @verbose || subjects_deactivated_count > 0
      puts "#{subjects_deactivated_count} subject record(s) marked as not current."
    end
    if @verbose
      puts "#{subjects_unchanged_count} subject record(s) untouched."
    end
    if @verbose || original_subject_count != final_subject_count
      puts "Started with #{original_subject_count} current subjects and finished with #{final_subject_count}."
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
    sb_tg_ids =
      @tutorgroups.collect { |tg| tg.dbrecord ? tg.dbrecord.id : nil }.compact
    #
    #  This next line isn't quite the right selection.  The problem is
    #  we're simply selecting tutorgroups which are current *now*, but
    #  if the start date which we're working on is in the future then
    #  we we really want to know which ones will be current then.
    #
    #  The effect is we keep setting an end-date for these groups,
    #  in the future, and we do it again every time the program is
    #  run.
    #
    #  Should fix.
    #
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

  def do_teachinggroups(populate = true)
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
      #  Finding the subject id is something which can be done only
      #  after all the subject records have been created.
      #
      tg.find_subject_id
      #
      #  There must be a more idiomatic way of doing this.
      #
      loaded,
      reincarnated,
      changed,
      unchanged,
      member_loaded,
      member_removed,
      member_unchanged = tg.ensure_db(self, populate)
      tg_loaded_count          += loaded
      tg_reincarnated_count    += reincarnated
      tg_changed_count         += changed
      tg_unchanged_count       += unchanged
      tgmember_loaded_count    += member_loaded
      tgmember_removed_count   += member_removed
      tgmember_unchanged_count += member_unchanged
      #
      #  Staff aren't members of the group, and so aren't handled by
      #  the generic group code.
      #
      tg.ensure_staff
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

  def do_otherhalfgroups
    changed_count      = 0
    unchanged_count    = 0
    loaded_count       = 0
    reincarnated_count = 0
    member_removed_count   = 0
    member_unchanged_count = 0
    member_loaded_count    = 0
    at_start = Otherhalfgroup.current.count
    @ohgroups.each do |g|
#      puts "Processing #{g.name}"
#      puts g.inspect
      #
      #  There must be a more idiomatic way of doing this.
      #
      loaded,
      reincarnated,
      changed,
      unchanged,
      member_loaded,
      member_removed,
      member_unchanged = g.ensure_db(self)
      loaded_count          += loaded
      reincarnated_count    += reincarnated
      changed_count         += changed
      unchanged_count       += unchanged
      member_loaded_count    += member_loaded
      member_removed_count   += member_removed
      member_unchanged_count += member_unchanged
    end
    #
    #  It's possible that a group has ceased to exist entirely,
    #  in which case we will still have a record in our d/b for it (possibly
    #  with members) but we need to record its demise.
    #
    deleted_count = 0
    sb_g_ids = @ohgroups.collect { |g| g.dbrecord.id }.compact
    db_g_ids = Otherhalfgroup.current.collect {|dbg| dbg.id}
    extra_ids = db_g_ids - sb_g_ids
    extra_ids.each do |eid|
      dbg = Otherhalfgroup.find(eid)
      puts "Other half group #{dbg.name} (#{dbg.id}) exists in the d/b but not in the files." if @verbose
      dbg.ceases_existence(@start_date)
      deleted_count += 1
    end
    at_end = Otherhalfgroup.current.count
    if @verbose || deleted_count > 0
      puts "#{deleted_count} other half group records deleted."
    end
    if @verbose || changed_count > 0
      puts "#{changed_count} other half group records amended."
    end
    if @verbose
      puts "#{unchanged_count} other half group records untouched."
    end
    if @verbose || loaded_count > 0
      puts "#{loaded_count} other half group records created."
    end
    if @verbose || reincarnated_count > 0
      puts "#{reincarnated_count} other half group records reincarnated."
    end
    if @verbose || member_removed_count > 0
      puts "Removed #{member_removed_count} pupils from other half groups."
    end
    if @verbose
      puts "Left #{member_unchanged_count} pupils where they were."
    end
    if @verbose || member_loaded_count > 0
      puts "Added #{member_loaded_count} pupils to other half groups."
    end
    if @verbose || at_start != at_end
      puts "Started with #{at_start} other half groups and finished with #{at_end}."
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
        lessons = lessons.select {|lesson| lesson.exists_on?(date)}
        puts "#{lessons.count} lessons for #{date.to_s}" if @verbose
        lessons.each do |lesson|
          #
          #  Make sure each of these lessons exists in the d/b and
          #  at the right time.
          #
          created_count, amended_count =
            lesson.ensure_db(date, @event_source, @verbose)
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
        puts "No lessons for #{date.to_s}" if @verbose
      end
      #
      #  Anything in the database which we need to remove?
      #
      dbevents = Event.events_on(date,          # Start date
                                 nil,           # End date
                                 nil,           # Categories
                                 @event_source, # Event source
                                 nil,           # Resource
                                 nil,           # Owner
                                 true)          # And non-existent
      dbhashes = dbevents.collect {|dbe| dbe.source_hash}.uniq
      if lessons
        mishashes = lessons.collect {|lesson| lesson.source_hash}
      else
        mishashes = []
      end
      puts "#{mishashes.size} events in MIS and #{dbhashes.size} in the d/b." if @verbose
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
    end
    if event_created_count > 0 || @verbose
      puts "#{event_created_count} timetable events added."
    end
    if event_amended_count > 0 || @verbose
      puts "#{event_amended_count} timetable events amended."
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

  #
  #  Very like doing the timetable, but an idealised week/fortnight which
  #  is used to produce printed timetables.
  #
  def do_ideal_cycle
    start_date = Setting.tt_store_start
    tt_cycle_weeks = Setting.tt_cycle_weeks
    if start_date &&
       (tt_cycle_weeks == 1 || tt_cycle_weeks == 2) &&
       @timetable.respond_to?(:lessons_by_day)
      end_date = (start_date + tt_cycle_weeks.weeks) - 1.day
      puts "Loading ideal cycle at #{start_date} to #{end_date}" if @verbose
      event_created_count         = 0
      event_deleted_count         = 0
      event_amended_count         = 0
      resources_added_count       = 0
      resources_removed_count     = 0
      set_to_naming_count         = 0
      set_to_not_naming_count     = 0
      tt_cycle_weeks.times do |week_no|
        Setting.first_tt_day.upto(Setting.last_tt_day) do |tt_day|
          date = start_date + week_no.weeks + tt_day.days
          puts "Processing #{date}" if @verbose
          lessons = @timetable.lessons_by_day(week_no, tt_day)
          if lessons
            puts "#{lessons.count} lessons for #{date.to_s}" if @verbose
            lessons.each do |lesson|
              #
              #  Make sure each of these lessons exists in the d/b and
              #  at the right time.
              #
              created_count, amended_count =
                lesson.ensure_db(date, @event_source, @verbose)
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
            puts "No lessons for #{date.to_s}" if @verbose
          end
          #
          #  Anything in the database which we need to remove?
          #
          dbevents = Event.events_on(date,          # Start date
                                     nil,           # End date
                                     nil,           # Categories
                                     @event_source, # Event source
                                     nil,           # Resource
                                     nil,           # Owner
                                     true)          # And non-existent
          dbhashes = dbevents.collect {|dbe| dbe.source_hash}.uniq
          if lessons
            mishashes = lessons.collect {|lesson| lesson.source_hash}
          else
            mishashes = []
          end
          puts "#{mishashes.size} events in MIS and #{dbhashes.size} in the d/b." if @verbose
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
        end
      end
      if event_created_count > 0 || @verbose
        puts "#{event_created_count} timetable events added."
      end
      if event_amended_count > 0 || @verbose
        puts "#{event_amended_count} timetable events amended."
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

  #
  #  Pass the name of the group and array of the members that should be
  #  in it.
  #
  #  These used to go in the current era, but now go in the perpetual
  #  era.  Any left over in the current era get moved to the perpetual
  #  era.
  #
  def ensure_membership(group_name, members, member_class)
    members_added   = 0
    members_removed = 0
    group = Group.no_owner.vanillagroups.find_by(name: group_name,
                                               era_id: Setting.perpetual_era.id)
    unless group
      group = Group.no_owner.vanillagroups.find_by(name: group_name,
                                                 era_id: @era.id)
      if group
        #
        #  Need to move this to the perpetual era.
        #
        group.era     = Setting.perpetual_era
        group.ends_on = nil
        group.save
        puts "Moved group #{group.name} to the perpetual era."
      end
    end
    unless group
      group = Vanillagroup.new(name:      group_name,
                               era:       Setting.perpetual_era,
                               starts_on: @start_date,
                               current:   true)
      group.save!
      group.reload
      puts "\"#{group_name}\" group created."
    end

    #
    #  We don't intend to have mixtures of types in groups, but we might.
    #  Therefore use element_ids as our unique identifiers, rather than
    #  the entity's ids.  The latter are unique for a given type of entity,
    #  but not across types.
    #
    #  Also allow for the odd nil entry by ignoring it.
    #
    #  It's also just possible that we will receive an entry with no
    #  element - typically happens because a member of staff has not
    #  been set up correctly in iSAMS.  Cope with that too.
    #
    intended_member_ids = members.compact.collect {|m|
      m.element ?  m.element.id : nil
    }.compact
    current_member_ids = group.members(@start_date, false, false).collect {|m| m.element.id}
    to_remove = current_member_ids - intended_member_ids
    to_add = intended_member_ids - current_member_ids
    to_remove.each do |member_id|
      group.remove_member(Element.find(member_id), @start_date)
      members_removed += 1
    end
    to_add.each do |member_id|
      group.add_member(Element.find(member_id), @start_date)
      members_added += 1
    end
    if @verbose || members_removed > 0
      puts "#{members_removed} removed from \"#{group_name}\" group."
    end
    if @verbose || members_added > 0
      puts "#{members_added} added to \"#{group_name}\" group."
    end
  end

  #
  #  Create some hard-coded special groups, using information available
  #  only at this point.
  #
  def do_auto_groups
    ensure_membership("All staff",
                      Staff.active.current.to_a,
                      Staff)
    ensure_membership("All pupils",
                      Pupil.current.to_a,
                      Pupil)
    pupils_by_year = Hash.new
    #
    #  Since the mapping of NC year to our years is not necessarily linear,
    #  do the conversion before the grouping.
    #
    @pupils.each do |pupil|
      (pupils_by_year[local_yeargroup(pupil.nc_year)] ||= Array.new) << pupil.dbrecord
    end
    pupils_by_year.each do |local_year, pupils|
      ensure_membership("#{local_yeargroup_text_pupils(local_year)}",
                        pupils,
                        Pupil)
    end
    @houses.each do |house|
      #
      #  Occasionally one gets a house with no name sneaking through,
      #  typically because there is a student who is not assigned
      #  to a house.  Don't process these ones.
      #
      unless house.name.blank?
        pupils = house.pupils.collect {|pupil| pupil.dbrecord}
        ensure_membership("#{local_format_house_name(house)} pupils",
                          pupils,
                          Pupil)
        #
        #  And by year?
        #
        pupils_by_year = Hash.new
        house.pupils.each do |pupil|
          (pupils_by_year[local_yeargroup(pupil.nc_year)] ||= Array.new) << pupil.dbrecord
        end
        #
        #  For some houses it doesn't make sense to stratify by year, but
        #  this is decided individually by each school.
        #
        if local_stratify_house?(house)
          pupils_by_year.each do |local_year, pupils|
            if Setting.ordinalize_years?
              year_bit = "#{local_year.ordinalize} year"
            else
              year_bit = "year #{local_year}"
            end
            ensure_membership("#{local_format_house_name(house)} #{year_bit}",
                              pupils,
                              Pupil)
          end
        end
      end
    end
    if self.respond_to?(:do_local_auto_groups)
      do_local_auto_groups
    end
    @subjects.each do |subject|
      #
      #  Who teaches this subject at all?
      #
      dbteachers =
        subject.teachers.collect {|t| t.dbrecord}.
                compact.select {|dbr| dbr.active}
      if dbteachers.size > 0
        ensure_membership("#{subject.name} teachers",
                          dbteachers,
                          Staff)
      end
      #
      #  And by year?
      #
      subject.year_teachers.each do |yeargroup, teachers|
        dbteachers =
          teachers.collect {|t| t.dbrecord}.
                  compact.select {|dbr| dbr.active}
        if dbteachers.size > 0
          ensure_membership("#{local_yeargroup_text(yeargroup)} #{subject.name} teachers",
                            dbteachers,
                            Staff)
        end
      end
      #
      #  Who studies this subject?  We don't actually make the pupils
      #  direct members of our automatic group.  Instead we make their
      #  teaching groups members, and thus the pupils inherit membership.
      #
      dbgroups = subject.groups.collect {|g| g.dbrecord}.compact
      if dbgroups.size > 0
        ensure_membership("#{subject.name} pupils",
                          dbgroups,
                          Group)
      end
      #
      #  And again, but broken down by year.
      #
      subject.year_groups.each do |yeargroup, groups|
        dbgroups = groups.collect {|g| g.dbrecord}.compact
        if dbgroups.size > 0
          ensure_membership("#{local_yeargroup_text(yeargroup)} #{subject.name} pupils",
                            dbgroups,
                            Group)
        end
      end
    end
    #
    #  Teachers by the year group which they teach - very useful for
    #  parents' evenings.
    #
    MIS_Subject.teachers_by_year do |yeargroup, teachers|
      dbteachers =
        teachers.collect {|t| t.dbrecord}.
                compact.select {|dbr| dbr.active}
      if dbteachers.size > 0
        ensure_membership("#{local_yeargroup_text(yeargroup)} teachers",
                          dbteachers,
                          Staff)
      end
    end
    #
    #  And now a collection of everyone who teaches at all.
    #
    dbteachers = MIS_Subject.all_teachers.collect {|t| t.dbrecord}.
                             compact.select {|dbr| dbr.active}
    if dbteachers.size > 0
      ensure_membership("Teaching staff",
                        dbteachers,
                        Staff)
    end
  end

  EXTRA_GROUP_FILES = [
    {file_name: "extra_staff_groups.yml", dbclass: Staff},
    {file_name: "extra_pupil_groups.yml", dbclass: Pupil},
    {file_name: "extra_group_groups.yml", dbclass: Group}
  ]

  def do_extra_groups
    EXTRA_GROUP_FILES.each do |control_data|
      begin
        file_data =
          YAML.load(
            File.open(Rails.root.join(IMPORT_DIR, control_data[:file_name])))
        if file_data
          file_data.each do |group_name, members|
            if members
              dbrecords = members.collect do |m|
                if control_data[:dbclass].respond_to?(:active)
                  dbrecord = control_data[:dbclass].active.current.find_by(name: m)
                else
                  dbrecord = control_data[:dbclass].current.find_by(name: m)
                end
                unless dbrecord
                  puts "Can't find #{m} for extra group #{group_name}"
                end
                dbrecord
              end.compact
            else
              dbrecords = []
            end
            ensure_membership(group_name, dbrecords, control_data[:dbclass])
          end
        end
      rescue Errno::ENOENT => e
        puts "No file #{control_data[:file_name]}." if @verbose
      end
    end
  end


  def do_recurring_events
    puts "Processing recurring events" if @verbose
    events_added_count = 0
    events_deleted_count = 0
    resources_added_count = 0
    resources_removed_count = 0
    #
    #  First we need to load the events from files.
    #
    res = RecurringEventStore.new
    Dir[Rails.root.join(IMPORT_DIR, "recurring", "*.yml")].each do |filename|
      begin
        res.note_events(RecurringEvent.readfile(filename).select {|e| e.find_resources})
      rescue Exception => e
        puts "Error processing #{filename}"
        puts e
      end
    end
    @start_date.upto(@era.ends_on) do |date|
      puts "Processing #{date}" if @verbose
      week_letter = @week_identifier.week_letter(date)
      events = res.events_on(date, week_letter)
      existing_events = Event.events_on(date,
                                        date,
                                        nil,
                                        @yaml_source,
                                        nil,
                                        nil,
                                        true)
      #
      #  We count duties from our input file and the database as being
      #  the same one if they have the same title, the same start time
      #  the same end time and the same category.
      #
      events.each do |event|
        if event.all_day
          existing_event = existing_events.detect {|ed|
            ed.body      == event.title &&
            ed.all_day? &&
            ed.eventcategory == event.eventcategory
          }
        else
          starts_at =
            Time.zone.parse("#{date.to_s} #{event.starts}")
          ends_at =
            Time.zone.parse("#{date.to_s} #{event.ends}")
          existing_event = existing_events.detect {|ed|
            ed.body      == event.title &&
            ed.starts_at == starts_at &&
            ed.ends_at   == ends_at &&
            ed.eventcategory == event.eventcategory
          }
        end
        if existing_event
          #
          #  Remove from the array.  We will deal with any leftovers
          #  at the end.
          #
          existing_events = existing_events - [existing_event]
          save_needed = false
          #
          #  Check its greyed-ness is right.
          #
          if existing_event.non_existent != event.greyed
            existing_event.non_existent = event.greyed
            save_needed = true
          end
          #
          #  And organiser?
          #
          if existing_event.organiser != event.organiser_element
            existing_event.organiser = event.organiser_element
            save_needed = true
          end
          existing_event.save! if save_needed
        else
          #
          #  Event needs creating in the database.
          #
          existing_event = Event.new
          existing_event.body = event.title
          existing_event.eventcategory = event.eventcategory
          existing_event.eventsource   = @yaml_source
          if event.all_day
            existing_event.all_day   = true
            existing_event.starts_at = date
            existing_event.ends_at   = date + 1.day
          else
            existing_event.starts_at     = starts_at
            existing_event.ends_at       = ends_at
          end
          existing_event.non_existent  = event.greyed
          existing_event.organiser     = event.organiser_element
          existing_event.save!
          existing_event.reload
          events_added_count += 1
        end
        #
        #  Now check that the resources match.
        #
        requested_ids = event.resource_ids
        current_ids = existing_event.elements.collect {|e| e.id}
        to_add = requested_ids - current_ids
        de_trop = current_ids - requested_ids
        to_add.each do |id|
#            puts "Adding element with id #{id}."
          c = Commitment.new
          c.event_id = existing_event.id
          c.element_id = id
          c.save!
          resources_added_count += 1
        end
        if de_trop.size > 0
          existing_event.commitments.each do |c|
            if de_trop.include?(c.element_id)
              c.destroy
              resources_removed_count += 1
            end
          end
        end
        #
        #  And what about notes, if any?
        #  There may well be other notes attached to our event - either
        #  by a user or by the clash checker.  Interest ourselves only
        #  in notes of type "yaml" - those are ours.
        #
        existing_note = existing_event.notes.yaml.take
        new_note = event.note
        #
        #  These are different kinds of things, but they both use
        #  nil to indicate that they don't exist.
        #
        if existing_note
          if new_note
            #
            #  Just need to make sure the text is the same.
            #
            unless existing_note.contents == new_note
              existing_note.contents = new_note
              existing_note.save!
            end
          else
            #
            #  Get rid of the existing note.
            #
            existing_note.destroy
          end
        else
          if new_note
            #
            #  Create a note with this text.
            #
            existing_event.notes.create!({
              contents:  new_note,
              note_type: :yaml
            })
          else
            #
            #  Neither exists - nothing to do.
            #
          end
        end
      end
      #
      #  Any of the existing events left?
      #
      existing_events.each do |ed|
        ed.destroy
        events_deleted_count += 1
      end
    end
    if events_added_count > 0 || @verbose
      puts "Added #{events_added_count} recurring events."
    end
    if events_deleted_count > 0 || @verbose
      puts "Deleted #{events_deleted_count} recurring events."
    end
    if resources_added_count > 0 || @verbose
      puts "Added #{resources_added_count} resources to recurring events."
    end
    if resources_removed_count > 0 || @verbose
      puts "Removed #{resources_removed_count} resources from recurring events."
    end
  end

  def check_recurring
    puts "Checking recurring events" if @verbose
    #
    #  Loading them will check them.
    #
    had_error = false
    res = RecurringEventStore.new
    Dir[Rails.root.join(IMPORT_DIR, "recurring", "*.yml")].each do |filename|
      begin
        puts "Checking #{filename}"
        file_had_issues = false
        res.note_events(RecurringEvent.readfile(filename).select {|e|
          if e.find_resources
            true
          else
            had_error = true
            file_had_issues = true
            false
          end
        })
        if file_had_issues
          puts "Issues found in #{filename}"
        end
      rescue Exception => e
        puts "Error processing #{filename}"
        puts e
        had_error = true
      end
    end
    unless had_error || @options.quiet
      puts "No problems found."
    end
  end

  #
  #  The name "Tag Groups" comes from SchoolBase, but they can be any
  #  kind of ad-hoc group which your MIS lets individual users set up.
  #
  def do_customgroups
    tg_loaded_count          = 0
    tg_reincarnated_count    = 0
    tg_changed_count         = 0
    tg_unchanged_count       = 0
    tg_deleted_count         = 0
    tgmember_loaded_count    = 0
    tgmember_removed_count   = 0
    tgmember_unchanged_count = 0
    @customgroups.each do |tg|
      #
      #  We only bother with custom groups which belong to an identifiable
      #  member of staff, and where that member of staff has already
      #  logged on to Scheduler.  This has been checked at initialisation.
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
    #  And are there any in the database which have disappeared from
    #  the MIS?  This is the only way they're going to get deleted, since
    #  users can't delete them through the Scheduler web i/f.
    #
    #  Note that this uses a different algorithm from that used by
    #  teaching groups.  There we look at the dbrecord ids and see if
    #  there are any extra ones.  Here we're relying on the source_id_str
    #  Not sure which I prefer, but it's worth noting and thinking about.
    #
    Group.taggroups.
          current.
          where(datasource_id: MIS_Record.primary_datasource_id).
          each do |dbtg|
      unless @customgroup_hash[dbtg.source_id_str]
        puts "Custom group \"#{dbtg.name}\" seems to have gone from MIS."
        dbtg.ceases_existence
        tg_deleted_count += 1
      end
    end
    if @verbose || tg_deleted_count > 0
      puts "#{tg_deleted_count} tag group records deleted."
    end
    if @verbose || tg_changed_count > 0
      puts "#{tg_changed_count} tag group records amended."
    end
    if @verbose
      puts "#{tg_unchanged_count} tag group records untouched."
    end
    if @verbose || tg_loaded_count > 0
      puts "#{tg_loaded_count} tag group records created."
    end
    if @verbose || tg_reincarnated_count > 0
      puts "#{tg_reincarnated_count} tag group records reincarnated."
    end
    if @verbose || tgmember_removed_count > 0
      puts "Removed #{tgmember_removed_count} pupils from tag groups."
    end
    if @verbose
      puts "Left #{tgmember_unchanged_count} pupils where they were."
    end
    if @verbose || tgmember_loaded_count > 0
      puts "Added #{tgmember_loaded_count} pupils to tag groups."
    end
  end

  #
  #  Add cover to existing lessons.
  #
  def do_cover
    covers_added = 0
    covers_amended = 0
    covers_deleted = 0
    invigilations_added = 0
    invigilations_amended = 0
    invigilations_deleted = 0
    cover_clashes = []
    cover_oddities = []
    covers_processed = 0
    invigilations_processed = 0
    #
    #  First group all the proposed covers by date.
    #
    covers_by_date = Hash.new
    invigilations_by_date = Hash.new
    max_cover_date = MIS_Cover.last_existing_cover_date(@start_date)
    max_invigilation_date = @start_date
    covered_property = Property.find_by(name: "Covered")
    @covers.each do |sc|
      covers_processed += 1
      if covers_by_date[sc.date]
        covers_by_date[sc.date] << sc
      else
        covers_by_date[sc.date] = [sc]
        if sc.date > max_cover_date
          max_cover_date = sc.date
        end
      end
    end
    #
    #  Now for the actual processing.  Note that we may well not do these
    #  in date order, but that shouldn't actually matter.
    #
    #  Second thought - we do need to do them in order, because we need
    #  to process even those dates where we haven't been given any cover
    #  records.  There may be one in our d/b on that date which needs
    #  removing.
    #
    @start_date.upto(max_cover_date) do |date|
      mis_covers = covers_by_date[date] || []
      #
      #  Now need to get the existing covers for this date and check
      #  that they match.
      #
      #  We are interested only in covers where the commitment record
      #  contains a source ID - i.e. it came from the MIS.  Manually
      #  created ones do not have a source ID and we leave them alone.
      #
      existing_covers =
        Commitment.commitments_on(
          startdate: date,
          include_nonexistent: true).covering_commitment.with_source_id
      mis_ids = mis_covers.collect {|mc| mc.source_id}.uniq
      db_ids = existing_covers.collect {|ec| ec.source_id}.uniq
      db_only = db_ids - mis_ids
      db_only.each do |db_id|
        #
        #  It's possible there's more than one db record with the same
        #  id - Need to get rid of all of them.
        #
        if @verbose
          puts "Deleting covers with source_id #{db_id ? db_id : "nil"}."
        end
        existing_covers.select {|ec| ec.source_id == db_id}.each do |ec|
          event = ec.event
          ec.destroy
          covers_deleted += 1
          if covered_property && !event.covered?
            event.lose_property(covered_property)
          end
        end
      end
      mis_covers.each do |mc|
        added, amended, deleted, clashes, oddities = mc.ensure_db(self, covered_property)
        covers_added += added
        covers_amended += amended
        covers_deleted += deleted
        cover_clashes += clashes
        cover_oddities += oddities
      end
    end
    if covers_added > 0 || @verbose
      puts "Added #{covers_added} instances of cover."
    end
    if covers_amended > 0 || @verbose
      puts "Amended #{covers_amended} instances of cover."
    end
    if covers_deleted > 0 || @verbose
      puts "Deleted #{covers_deleted} instances of cover."
    end
    if invigilations_added > 0 || @verbose
      puts "Added #{invigilations_added} instances of invigilation."
    end
    if invigilations_amended > 0 || @verbose
      puts "#{invigilations_amended} amendments to instances of invigilation."
    end
    if invigilations_deleted > 0 || @verbose
      puts "Deleted #{invigilations_deleted} instances of invigilation."
    end
    unless self.options.quiet
      puts "Processed #{covers_processed} covers and #{invigilations_processed} invigilations."
    end
    if cover_clashes.size > 0 ||
       cover_oddities.size > 0
      puts "#{cover_clashes.size} apparent cover clashes."
      puts "#{cover_oddities.size} apparent cover oddities."
      if @send_emails
        User.arranges_cover.each do |user|
          UserMailer.cover_clash_email(user,
                                       cover_clashes,
                                       cover_oddities).deliver_now
        end
      end
    else
      puts "No apparent cover issues." unless self.options.quiet
    end
  end

end
