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

  def complete?
    @schedule_entry != nil && @staff_covering != nil && @staff_covered != nil
  end

  def self.construct(loader, isams_data)
    covers = Array.new
    isams_covers = isams_data[:covers]
    if isams_covers
      isams_covers.each do |key, record|
        cover = MIS_Cover.new(loader, record)
        if cover.complete?
          covers << cover
        else
          puts "Can't find #{record.teacher_school_id} to do cover."
        end
      end
    else
      puts "Can't find iSAMS covers."
    end
    covers
  end

end

