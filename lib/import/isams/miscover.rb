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
  #  If you want to have a lesson with multiple teachers in iSAMS then
  #  you need to set up multiple otherwise-identical lessons.  Scheduler
  #  will then merge them into a single lesson as it imports them.
  #
  #  This then means that we need to keep track of which teacher was
  #  teaching each original lesson so that we can recognize which teacher
  #  is being covered when that happens.
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
      #
      #  Where lessons have been merged, the merged lesson record contains
      #  a hash allowing us to work out who was the original teacher of
      #  the indicated lesson.
      #
      @staff_covered      =
        loader.secondary_staff_hash[
          @schedule_entry.original_teacher_id(@schedule_id)]
      @starts_at          = @schedule_entry.period_time.starts_at
      @ends_at            = @schedule_entry.period_time.ends_at
    else
      #
      #  It transpires that iSAMS is pretty bad at keeping its database
      #  self-consistent.  It starts off OK, but gradually the errors
      #  build.  After a timetable change, there can be hundreds of
      #  orphaned cover records (cover record but no corresponding lesson).
      #  Don't log them individually if the --quiet option is specified.
      #
      #  The slurping code has already dropped all those in the past, so
      #  the number will gradually decrease.
      #
      puts "Unable to find covered lesson with ID #{@schedule_id}." unless loader.options.quiet
    end
  end

  def complete?(quiet)
    unless quiet
      if @schedule_entry
        if @staff_covered && @staff_covered.dbrecord
          #
          #  We need to check the dbrecord's idea of the staff member's
          #  active status and not ours, because we may disagree and
          #  the d/b is definitive.  It is possible that we think the
          #  staff member is not active, but the dbrecord has been set
          #  manually to active.
          #
          unless @staff_covered.dbrecord.active
            puts "#{@staff_covered.name} seems to be covered but not active."
          end
        else
          puts "Schedule entry #{@schedule_id} seems to have no staff to cover."
        end
        if @staff_covering && @staff_covering.dbrecord
          unless @staff_covering.dbrecord.active
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
      @staff_covering.dbrecord &&
      @staff_covering.dbrecord.active &&
      @staff_covered != nil &&
      @staff_covered.dbrecord &&
      @staff_covered.dbrecord.active
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

