# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class MIS_Cover

  #
  #  Pass has a very naive approach to cover, recording only which lesson
  #  is being covered and by whom.  Since it also can't cope with more than
  #  one teacher for a lesson, it doesn't need to be any more thorough.
  #
  #  Scheduler is more sophisticated - you can have any number of teachers
  #  involved in a given lesson, and each of these could be separately
  #  covered.
  #
  #  If you want to have a lesson with multiple teachers in Pass then
  #  you need to set up multiple otherwise-identical lessons.  Scheduler
  #  will then merge them into a single lesson as it imports them.
  #
  #  This then means that we need to keep track of which teacher was
  #  teaching each original lesson so that we can recognize which teacher
  #  is being covered when that happens.
  #
  def initialize(loader, entry, other_entry)
    @covering_staff_id = entry.covering_staff_id + 4
    @covered_staff_id  = other_entry.covered_staff_id
    @covering_staff_name = entry.coverer_name
    @covered_staff_name  = other_entry.covered_staff_name
    @cover_id          = entry.cover_id
    @task_start        = entry.task_start
    @date              = @task_start.to_date
    @task_end          = entry.task_end
    @starts_at         = @task_start.strftime("%H:%M")
    @ends_at           = @task_end.strftime("%H:%M")
    #
    #  Incredibly, the pass data export provides no means to link
    #  the cover instance directly to the relevant lesson.  We
    #  need to find it for ourselves.
    #
    #  Our method is not terribly efficient, but we shouldn't have
    #  vast numbers to deal with.
    #
    candidate_lessons = loader.timetable.lessons_on(@task_start.to_date)
    matches = candidate_lessons.select { |l|
      l.taught_by?(@covered_staff_id) &&
        l.period_time.starts_at == @starts_at &&
        l.period_time.ends_at   == @ends_at
    }
    if matches.size == 1
      @schedule_entry = matches[0]
      @lesson_source_hash = @schedule_entry.source_hash
      @staff_covering     = loader.staff_by_name[@covering_staff_name]
      @staff_covered      = loader.staff_by_name[@covered_staff_name]
    elsif matches.size == 0
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
      puts "Unable to find covered lesson with ID #{@cover_id}." unless loader.options.quiet
    else
      puts "Too many matches for cover id #{@cover_id}"
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
          puts "Schedule entry #{@lesson_id} seems to have no staff to cover."
        end
        if @staff_covering && @staff_covering.dbrecord
          unless @staff_covering.dbrecord.active
            puts "Staff member #{@covering_staff_id} not active to do cover."
          end
        else
          puts "Staff member #{@covering_staff_id} not found to do cover."
        end
      else
        puts "Can't find schedule entry #{@lesson_id} to arrange cover."
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

  def source_id
    #
    #  This is a bit tricky.  Pass provides not the raw data but
    #  data which have been "helpfully" massaged for ease of use.
    #  The trouble is, it has had the opposite effect.
    #
    #  Try to construct something which will be unique, at least for
    #  the day.
    #
    #((((@lesson_id << 8) + @covering_staff_id) << 8) + (@task_start.seconds_since_midnight / 60)) & 0xffffffff
    #
    #  Forget that comment.  Pass does provide an ID, it's just badly
    #  mis-named.
    #
    @cover_id
  end

  def self.construct(loader, mis_data)
    covers = Array.new
    dropped_count = 0
    mis_covers = mis_data[:cover_records]
    mis_cover_needs = mis_data[:cover_needed_records]
    if mis_covers && mis_cover_needs
      mis_covers.each do |record|
        other_record = mis_cover_needs[record.cover_id]
        if other_record
          cover = MIS_Cover.new(loader, record, other_record)
          if cover.complete?(loader.options.quiet)
            covers << cover
          else
            dropped_count += 1
          end
        else
          dropped_count += 1
        end
      end
      if dropped_count > 0 || loader.options.verbose
        puts "Dropped #{dropped_count} #{"cover".pluralize(dropped_count)}."
      end
    else
      puts "Can't find Pass covers."
    end
    covers
  end

end

