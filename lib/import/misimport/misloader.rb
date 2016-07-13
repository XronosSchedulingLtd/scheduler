class MIS_Loader

  attr_reader :options,
              :era,
              :start_date,
              :pupils,
              :pupil_hash,
              :staff_hash,
              :location_hash,
              :subject_hash,
              :teachinggroup_hash

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
    end
    @tutorgroups = MIS_Tutorgroup.construct(self, whatever)
    puts "Got #{@tutorgroups.count} tutorgroups." if options.verbose
    @teachinggroups = MIS_Teachinggroup.construct(self, whatever)
    puts "Got #{@teachinggroups.count} teaching groups." if options.verbose
    @teachinggroup_hash = Hash.new
    @teachinggroups.each do |tg|
      @teachinggroup_hash[tg.source_id] = tg
    end
    self.mis_specific_preparation
    @timetable = MIS_Timetable.new(self, whatever)
    puts "Got #{@timetable.entry_count} timetable entries." if options.verbose
    @timetable.note_hiatuses(self, @hiatuses)
    @timetable.note_subjects_taught
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
    @hiatuses = Hiatus.load_hiatuses(self)
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
        lessons = lessons.select {|lesson| lesson.exists_on?(date)}
        puts "#{lessons.count} lessons for #{date.to_s}" if @verbose
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
    group = Group.system.vanillagroups.find_by(name: group_name,
                                               era_id: Setting.perpetual_era.id)
    unless group
      group = Group.system.vanillagroups.find_by(name: group_name,
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
    intended_member_ids = members.compact.collect {|m| m.element.id}
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
    #
    #  Staff by house they are tutors in.
    #
    all_tutors = []
    tutors_by_year = {}
    tges_by_year = {}
    @houses.each do |house|
      tutors = []
      pupils = []
      house_tges_by_year = {}
      house.tugs.each do |tug|
        tutors << tug.staff.dbrecord
        all_tutors << tug.staff.dbrecord
        tutors_by_year[tug.yeargroup] ||= []
        tutors_by_year[tug.yeargroup] << tug.staff.dbrecord
        #
        #  And now, each of the pupils.
        #
        tug.pupils.each do |pupil|
          tges_by_year[tug.yeargroup] ||= []
          tges_by_year[tug.yeargroup] << pupil.dbrecord
          house_tges_by_year[tug.yeargroup] ||= []
          house_tges_by_year[tug.yeargroup] << pupil.dbrecord
          pupils << pupil.dbrecord
        end
      end
      if house.name == "Lower School"
        ensure_membership("#{house.name} tutors",
                          tutors,
                          Staff)
        ensure_membership("#{house.name} pupils",
                          pupils,
                          Pupil)
      else
        ensure_membership("#{house.name} House tutors",
                          tutors,
                          Staff)
        ensure_membership("#{house.name} House pupils",
                          pupils,
                          Pupil)
        house_tges_by_year.each do |year_group, pupils|
          ensure_membership("#{house.name} House #{year_group.ordinalize} year",
                            pupils,
                            Pupil)
        end
      end
    end
    middle_school_tutors = []
    upper_school_tutors = []
    tutors_by_year.each do |year_group, tutors|
      ensure_membership("#{year_group.ordinalize} year tutors",
                        tutors,
                        Staff)
      #
      #  Lower school tutors already have their own group from the house
      #  processing.
      #
      if year_group == 3 ||
         year_group == 4 ||
         year_group == 5
        middle_school_tutors += tutors
      elsif year_group == 6 ||
            year_group == 7
        upper_school_tutors += tutors
      end
    end
    tges_by_year.each do |year_group, pupils|
      ensure_membership("#{year_group.ordinalize} year",
                        pupils,
                        Pupil)
    end
    ensure_membership("Middle school tutors", middle_school_tutors, Staff)
    ensure_membership("Upper school tutors", upper_school_tutors, Staff)
    ensure_membership("All tutors", all_tutors, Staff)
    ensure_membership("All pupils",
                      Pupil.current.to_a,
                      Pupil)
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
          ensure_membership("#{yeargroup.ordinalize} year #{subject.name} teachers",
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
          ensure_membership("#{yeargroup.ordinalize} year #{subject.name} pupils",
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
        ensure_membership("#{yeargroup.ordinalize} year teachers",
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

end
