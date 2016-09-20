class MIS_Cover

  #
  #  iSAMS has a very naive approach to cover, recording only which lesson
  #  is being covered and by whom.  Since it also can't cope with more than
  #  one teacher for a lesson, it doesn't need to be any more thorough.
  #
  #  Scheduler is more sophisticated - you can have any number of teachers
  #  involved in a given lesson, and each of these could be separately
  #  covered.
  #
  #  If and when we decide to merge iSAMS lesson records (because
  #  we've had to create duplicates in their d/b to cope with multi-teacher
  #  lessons) we'll also have to improve the handling here.
  #
  #  iSAMS does seem to have the ability to specify a cover classroom
  #  too.  If ICF decides to use this facility then it would make sense
  #  to bring the information through here too.  Scheduler can cope with
  #  any kind of resource being covered.
  #
  def initialize(loader, entry)
    @source_id          = entry.ident
    @date               = entry.date
    @schedule_id        = entry.schedule_id
    @cover_teacher_school_id = entry.teacher_school_id
    #
    #  Now, let's just make sure this schedule id makes sense.
    #
    @schedule_entry = loader.timetable.schedule.lesson_by_id(@schedule_id)
    if @schedule_entry
      @lesson_source_hash = @schedule_entry.source_hash
      @staff_covering     = loader.secondary_staff_hash[entry.teacher_school_id]
      @staff_covered      = @schedule_entry.staff[0]
      @starts_at          = @schedule_entry.period_time.starts_at
      @ends_at            = @schedule_entry.period_time.ends_at
    else
      puts "Unable to find covered lesson with ID #{@schedule_id}."
    end
  end

  def complete?(quiet)
    unless quiet
      if @schedule_entry
        unless @staff_covered
          puts "Schedule entry #{@schedule_id} seems to have no staff to cover."
        end
        if @staff_covering
          unless @staff_covering.active
            puts "Staff member #{@cover_teacher_school_id} not active to do cover."
          end
        else
          puts "Staff member #{@cover_teacher_school_id} not found to do cover."
        end
      else
        puts "Can't find schedule entry #{@schedule_id} to arrange cover."
      end
    end
    @schedule_entry != nil &&
      @staff_covering != nil &&
      @staff_covering.active &&
      @staff_covered != nil
  end

  def self.construct(loader, isams_data)
    covers = Array.new
    dropped_count = 0
    isams_covers = isams_data[:covers]
    if isams_covers
      isams_covers.each do |key, record|
        cover = MIS_Cover.new(loader, record)
        if cover.complete?(loader.options.quiet)
          covers << cover
        else
          dropped_count += 1
        end
      end
      if dropped_count > 0 || loader.options.verbose
        puts "Dropped #{dropped_count} #{"cover".pluralize(dropped_count)}."
      end
    else
      puts "Can't find iSAMS covers."
    end
    covers
  end

end

