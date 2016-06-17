class MIS_Loader

  attr_reader :verbose, :full_load, :era, :send_emails

  def read_mis_data(options)
    #
    #  We have no idea what "whatever" is - it's just something
    #  defined by the MIS-specific components.  Could be a large
    #  data structure, or simply a file handle.
    #
    whatever = prepare(options)
    @pupils = MIS_Pupil.slurp(whatever)
    puts "Got #{@pupils.count} pupils." if options.verbose
    @pupil_hash = Hash.new
    @pupils.each do |pupil|
      @pupil_hash[pupil.source_id] = pupil
    end
    @staff = MIS_Staff.slurp(whatever)
    puts "Got #{@staff.count} staff." if options.verbose
    @staff_hash = Hash.new
    @staff.each do |staff|
      @staff_hash[staff.source_id] = staff
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

end
