class MIS_Loader

  attr_reader :verbose,
              :full_load,
              :era,
              :start_date,
              :send_emails,
              :pupils,
              :pupil_hash,
              :staff_hash

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
    @staff.each do |staff|
      @staff_hash[staff.source_id] = staff
    end
    @locations = MIS_Location.construct(self, whatever)
    @tutorgroups = MIS_Tutorgroup.construct(self, whatever)
    puts "Got #{@tutorgroups.count} tutorgroups." if options.verbose
    @teachinggroups = MIS_Teachinggroup.construct(self, whatever)
    puts "Got #{@teachinggroups.count} teaching groups." if options.verbose
    @timetable = MIS_Timetable.new(self, whatever)
    puts "Got #{@timetable.entries.count} timetable entries." if options.verbose
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
    atomic_event_created_count         = 0
    atomic_event_deleted_count         = 0
    atomic_event_retimed_count         = 0
    atomic_event_recategorized_count   = 0
    resources_added_count              = 0
    resources_removed_count            = 0
    set_to_naming_count                = 0
    set_to_not_naming_count            = 0
    @start_date.upto(@era.ends_on) do |date|
      puts "Processing #{date}" if @verbose
      lessons = @timetable.lessons_on(date)
      if lessons
        puts "#{lessons.count} lessons for #{date.to_s}"
      else
        puts "No lessons for #{date.to_s}"
      end
if false
      if lessons
        lessons = lessons.select {|lesson| lesson.exists_on?(date)}
        dbevents = Event.events_on(date,                # Start date
                                   nil,                 # End date
                                   [@lesson_category,   # Categories
                                    @meeting_category,
                                    @supervised_study_category,
                                    @assembly_category,
                                    @chapel_category,
                                    @registration_category,
                                    @tutor_category],
                                   @event_source,       # Event source
                                   nil,                 # Resource
                                   nil,                 # Owner
                                   true)                # And non-existent
        dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
        dbids = dbatomic.collect {|dba| dba.source_id}.uniq
        dbhashes = dbcompound.collect {|dbc| dbc.source_hash}.uniq
        #
        #  A little bit of correction code.  Earlier I managed to reach
        #  the situation where two instances of the same event (from SB's
        #  point of view) were occuring on the same day.  If this happens,
        #  arbitrarily delete one of them before continuing.
        #
        deleted_something = false
        if dbids.size < dbatomic.size
          puts "Deleting #{dbatomic.size - dbids.size} duplicate events." if @verbose
          deleted_something = true
          dbids.each do |dbid|
            idsevents = dbatomic.select {|dba| dba.source_id == dbid}
            if idsevents.size > 1
              #
              #  We have one or more duplicates.
              #
              idsevents.each_with_index do |dbevent, i|
                if i > 0
                  dbevent.destroy
                end
              end
            end
          end
        end
        if dbhashes.size < dbcompound.size
          puts "Deleting #{dbcompound.size - dbhashes.size} duplicate events." if @verbose
          deleted_something = true
          dbhashes.each do |dbhash|
            hashesevents = dbcompound.select {|dbc| dbc.source_hash == dbhash}
            if hashesevents.size > 1
              #
              #  We have one or more duplicates.
              #
              hashesevents.each_with_index do |dbevent, i|
                if i > 0
                  dbevent.destroy
                end
              end
            end
          end
        end
        if deleted_something
          #
          #  And read again from the database.
          #
          dbevents = Event.events_on(date,
                                     nil,
                                     [@lesson_category,
                                      @meeting_category,
                                      @supervised_study_category,
                                      @assembly_category,
                                      @chapel_category,
                                      @registration_category,
                                      @tutor_category],
                                     @event_source,
                                     nil,
                                     nil,
                                     true)
          dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
          dbids = dbatomic.collect {|dba| dba.source_id}.uniq
          dbhashes = dbcompound.collect {|dbc| dbc.source_hash}.uniq
        end
        sbcompound, sbatomic = lessons.partition {|sbe| sbe.compound}
        sbids = sbatomic.collect {|sba| sba.timetable_ident}
        sbhashes = sbcompound.collect {|sbc| sbc.source_hash}
#          puts "#{sbatomic.size} atomic events in SB and #{dbatomic.size} in the d/b."
#          puts "#{sbcompound.size} compound events in SB and #{dbcompound.size} in the d/b."
        #
        #  First we'll do the atomic ones.
        #
        #  Anything in the database, but not in the SB files?
        #
        dbonly = dbids - sbids
        if dbonly.size > 0
          puts "Deleting #{dbonly.size} atomic events." if @verbose
          #
          #  These I'm afraid have to go.  Given only the source
          #  id we don't have enough to find the record in the d/b
          #  (because they repeat every fortnight) but happily we
          #  already have the relevant d/b record in memory.
          #
          dbonly.each do |dbo|
#              puts "Deleting record with id #{dbo}"
            dbrecord = dbatomic.find {|dba| dba.source_id == dbo}
            if dbrecord
#                puts "d/b record id is #{dbrecord.id}"
              dbrecord.destroy
            end
            atomic_event_deleted_count += 1
#              Event.find_by(source_id:        dbo,
#                            eventcategory_id: @lesson_category.id,
#                            eventsource_id:   @event_source.id).destroy
          end
        end
        #
        #  And now anything in the SB files which isn't in the d/b?
        #
        sbonly = sbids - dbids
        if sbonly.size > 0
          puts "Adding #{sbonly.size} atomic events." if @verbose
          sbonly.each do |sbo|
            lesson = @tte_hash[sbo]
            #
            #  For each of these, just create the event.  Resources
            #  will be handled later.
            #
            period_time = lesson.period_time
            event = Event.new
            event.body          = lesson.body_text(self)
            event.eventcategory = lesson.eventcategory(self)
            event.eventsource   = @event_source
            if lesson.lower_school
              event.starts_at     =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
                event.ends_at       =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
              else
              event.starts_at     =
                Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
              event.ends_at       =
                Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
            end
            event.approximate   = false
            event.non_existent  = lesson.suspended_on?(self, date)
            event.private       = false
            event.all_day       = false
            event.compound      = false
            event.source_id     = lesson.timetable_ident
            if event.save
              atomic_event_created_count += 1
              event.reload
              #
              #  Add it to our array of events which are in the d/b.
              #
              dbatomic << event
            else
              puts "Failed to save event #{event.inspect}"
            end
          end
        end
        #
        #  All the right atomic events should now be in the database.
        #  Run through them making sure they have the right time and
        #  the right resources.
        #
        sbatomic.each do |lesson|
          if event = dbatomic.detect {
            |dba| dba.source_id == lesson.timetable_ident
          }
            #
            #  Now have a d/b record (event) and a SB record (lesson).
            #
            changed = false
            period_time = lesson.period_time
            if lesson.lower_school
              starts_at =
                Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
              ends_at   =
                Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
            else
              starts_at =
                Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
              ends_at   =
                Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
            end
            if event.starts_at != starts_at
              event.starts_at = starts_at
              changed = true
            end
            if event.ends_at != ends_at
              event.ends_at = ends_at
              changed = true
            end
            if event.non_existent != lesson.suspended_on?(self, date)
              event.non_existent = lesson.suspended_on?(self, date)
#                puts "#{event.body} #{event.non_existent ? "suspended" : "un-suspended"} on #{date.to_s} at #{period_time.starts_at}"
              changed = true
            end
            if event.eventcategory_id != lesson.eventcategory(self).id
              event.eventcategory = lesson.eventcategory(self)
              atomic_event_recategorized_count += 1
              changed = true
            end
            if event.body != lesson.body_text(self)
              event.body = lesson.body_text(self)
              changed = true
            end
            if changed
              if event.save
                atomic_event_retimed_count += 1
              else
                puts "Failed to save amended event record."
              end
            end
            #
            #  And what about the resources?  We use our d/b element ids
            #  as unique identifiers.
            #
            sb_element_ids = Array.new
            sb_group_element_id = nil
            if group = @group_hash[lesson.group_ident]
              sb_element_ids << group.element_id
              #
              #  Atomic events only ever have one group, and if they have
              #  a group then they are lessons, and the group names the
              #  event.
              #
              sb_group_element_id = group.element_id
            end
            if staff = @staff_hash[lesson.staff_ident]
              sb_element_ids << staff.element_id
            end
            if location = @location_hash[lesson.room_ident]
              sb_element_ids << location.element_id
            end
            #
            #  The element_id method can return nil
            #
            sb_element_ids.compact!
            db_element_ids = event.commitments.collect {|c| c.element_id}
            db_only = db_element_ids - sb_element_ids
            sb_only = sb_element_ids - db_element_ids
            sb_only.each do |sbid|
              c = Commitment.new
              c.event       = event
              c.element_id  = sbid
              if sbid == sb_group_element_id
                c.names_event = true
              end
              c.save
              resources_added_count += 1
            end
            event.reload
            if db_only.size > 0
              event.commitments.each do |c|
                if db_only.include?(c.element_id) && !c.covering
                  c.destroy
                  resources_removed_count += 1
                end
              end
            end
            #
            #  Just temporary
            #
            shared = sb_element_ids - sb_only
            if shared.size > 0
              event.commitments.each do |c|
                if shared.include?(c.element_id)
                  if c.names_event && c.element_id != sb_group_element_id
                    puts "#{event.body} disagrees on event naming (A)" if @verbose
                    c.names_event = false
                    c.save
                    set_to_not_naming_count += 1
                  elsif !c.names_event && c.element_id == sb_group_element_id
                    puts "#{event.body} disagrees on event naming (B)" if @verbose
                    c.names_event = true
                    c.save
                    set_to_naming_count += 1
                  end
                end
              end
            end
          else
            puts "Very odd - d/b record #{lesson.timetable_ident} has disappeared."
          end
        end
        #
        #  And now on to the compound events.
        #
        #  Anything in the database, but not in the SB files?
        #
        dbonly = dbhashes - sbhashes
        if dbonly.size > 0
          puts "Deleting #{dbonly.size} compound events." if @verbose
          #
          #  These I'm afraid have to go.  Given only the source
          #  hash we don't have enough to find the record in the d/b
          #  (because they repeat every fortnight) but happily we
          #  already have the relevant d/b record in memory.
          #
          dbonly.each do |dbo|
            dbrecord = dbcompound.find {|dbc| dbc.source_hash == dbo}
            if dbrecord
              dbrecord.destroy
            end
            compound_event_deleted_count += 1
          end
        end
        #
        #  And now anything in the SB files which isn't in the d/b?
        #
        sbonly = sbhashes - dbhashes
        if sbonly.size > 0
          puts "Adding #{sbonly.size} compound events." if @verbose
          sbonly.each do |sbo|
            lesson = @ctte_hash[sbo]
            period_time = lesson.period_time
            #
            #  Although we're not going to attach the teachinggroup
            #  at the moment, we may need to find it to use its name
            #  as the event name.
            #
            dbgroup = nil
            unless lesson.meeting?
              if group = @group_hash[lesson.group_idents[0]]
                dbgroup = group.dbrecord
              end
            end
            if lesson.meeting? || dbgroup
              event = Event.new
              event.body          = lesson.body_text(self)
              event.eventcategory = lesson.eventcategory(self)
              event.eventsource   = @event_source
              if lesson.lower_school
                event.starts_at     =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
                event.ends_at       =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
              else
                event.starts_at     =
                  Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
                event.ends_at       =
                  Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
              end
              event.approximate   = false
              event.non_existent  = lesson.suspended_on?(self, date)
              event.private       = false
              event.all_day       = false
              event.compound      = true
              event.source_hash   = lesson.source_hash
              if event.save
                compound_event_created_count += 1
                event.reload
                #
                #  Add it to our array of events which are in the d/b.
                #
                dbcompound << event
              else
                puts "Failed to save event #{event.inspect}"
              end
            else
              puts "Not loading - lesson = #{lesson.source_hash}"
              puts "  original id = #{lesson.timetable_ident}"
#                puts "  period = #{period}"
              puts "  lesson.meeting = #{lesson.meeting?}"
              puts "  dbgroup = #{dbgroup}"
              puts "  group_ident = #{lesson.group_idents[0]}"
  #            puts "Not loading - lesson = #{lesson.timetable_ident}, dbgroup = #{dbgroup ? dbgroup.name : "Not found"}"
            end
          end
        end
        #
        #  All the right compound events should now be in the database.
        #  Run through them making sure they have the right time and
        #  the right resources.
        #
        sbcompound.each do |lesson|
          if event = dbcompound.detect {
            |dbc| dbc.source_hash == lesson.source_hash
          }
            #
            #  Now have a d/b record (event) and a SB record (lesson).
            #
            changed = false
            period_time = lesson.period_time
            if lesson.lower_school
              starts_at =
                Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
              ends_at   =
                Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
            else
              starts_at =
                Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
              ends_at   =
                Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
            end
            if event.starts_at != starts_at
              event.starts_at = starts_at
              changed = true
            end
            if event.ends_at != ends_at
              event.ends_at = ends_at
              changed = true
            end
            if event.non_existent != lesson.suspended_on?(self, date)
              event.non_existent = lesson.suspended_on?(self, date)
#                puts "#{event.body} #{event.non_existent ? "suspended" : "un-suspended"} on #{date.to_s} at #{period_time.starts_at}"
              changed = true
            end
#              if event.eventcategory_id == @registration_category.id ||
#                 event.eventcategory_id == @tutor_category.id
#                puts "Compound event #{event.id} has a surprising category."
#              end
            if event.eventcategory_id != lesson.eventcategory(self).id
              event.eventcategory = lesson.eventcategory(self)
              compound_event_recategorized_count += 1
              changed = true
            end
            if event.body != lesson.body_text(self)
              event.body = lesson.body_text(self)
              changed = true
            end
            if changed
              if event.save
                compound_event_retimed_count += 1
              else
                puts "Failed to save amended compound event record."
              end
            end
            #
            #  And what about the resources?  We use our d/b element ids
            #  as unique identifiers.
            #
            sb_element_ids = Array.new
            lesson.group_idents.each do |gi|
              if group = @group_hash[gi]
                sb_element_ids << group.element_id
              end
            end
            lesson.staff_idents.each do |si|
              if staff = @staff_hash[si]
                sb_element_ids << staff.element_id
              end
            end
            lesson.room_idents.each do |ri|
              if location = @location_hash[ri]
                sb_element_ids << location.element_id
              end
            end
            #
            #  The element_id method can return nil
            #
            sb_element_ids.compact!
            db_element_ids = event.commitments.collect {|c| c.element_id}
            db_only = db_element_ids - sb_element_ids
            sb_only = sb_element_ids - db_element_ids
            sb_only.each do |sbid|
              c = Commitment.new
              c.event      = event
              c.element_id = sbid
              c.save
              resources_added_count += 1
            end
            event.reload
            if db_only.size > 0
              event.commitments.each do |c|
                if db_only.include?(c.element_id) && !c.covering
                  c.destroy
                  resources_removed_count += 1
                end
              end
            end
          else
            puts "Very odd - d/b record #{lesson.source_hash} has disappeared."
          end
        end
      else
        puts "Couldn't find lesson entries for #{date.strftime("%A")}."
      end
end
    end
    if atomic_event_created_count > 0 || @verbose
      puts "#{atomic_event_created_count} atomic timetable events added."
    end
    if atomic_event_deleted_count > 0 || @verbose
      puts "#{atomic_event_deleted_count} atomic timetable events deleted."
    end
    if atomic_event_retimed_count > 0 || @verbose
      puts "#{atomic_event_retimed_count} atomic timetable events amended."
    end
    if atomic_event_recategorized_count > 0 || @verbose
      puts "#{atomic_event_recategorized_count} atomic timetable events re-categorized."
    end
    if resources_added_count > 0 || @verbose
      puts "#{resources_added_count} resources added to timetable events."
    end
    if resources_removed_count > 0 || @verbose
      puts "#{resources_removed_count} resources removed from timetable events."
    end
    if set_to_naming_count > 0 || @verbose
      puts "#{set_to_naming_count} commitments set as naming events."
    end
    if set_to_not_naming_count > 0 || @verbose
      puts "#{set_to_not_naming_count} commitments set as not naming events."
    end
  end

end
