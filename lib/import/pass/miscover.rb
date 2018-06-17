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
  #  Actually, the Pass cover records are a bit broken.  There is
  #  no absolutely sure way of establishing who is actually being
  #  covered.  All we can do is make an intelligent guess.
  #
  def initialize(loader, entry, other_entries)
    #
    #  First assemble data from the "doing cover" record.
    #
    @covering_staff_id   = entry.covering_staff_id
    @covering_staff_name = entry.coverer_name
    @staff_covering      = MIS_Staff.by_name(@covering_staff_name)
    @cover_id            = entry.cover_id
    @task_start          = entry.task_start
    @date                = @task_start.to_date
    @task_end            = entry.task_end
    @starts_at           = @task_start.strftime("%H:%M")
    @ends_at             = @task_end.strftime("%H:%M")
    #
    #  Now need to look at the "needing cover" records.
    #  Need one with the right start and end date/times which hasn't
    #  been used before.
    #
    plausible_entries = other_entries.select { |oe|
      oe.task_start == entry.task_start &&
      oe.task_end == entry.task_end &&
      oe.room_code == entry.room_code &&
      oe.task_code == entry.task_code &&
      !oe.used}
    #
    #  And we may still have more than one.  Very oddly, we get 
    #  "needing cover" records from Pass for staff who aren't
    #  actually teaching at the time given.  We need to
    #  avoid selecting one of those, because we will then fail
    #  later in trying to find the corresponding lesson.
    #
    unless plausible_entries.empty?
      candidate_lessons = loader.timetable.lessons_on(@task_start.to_date)
      plausible_entries.each do |pe|
        #
        #  A little check.
        #
        possible_staff = MIS_Staff.by_name(pe.covered_staff_name)
        if possible_staff
          if possible_staff.source_id != pe.covered_staff_id
            puts "IDs for #{pe.covered_staff_name} differ in cover needed file."
            puts "Staff listing: #{possible_staff.source_id}."
            puts "Cover needed: #{pe.covered_staff_id}."
          end
        else
          puts "Can't find #{pe.covered_staff_name} needing cover."
        end
        matches = candidate_lessons.select { |l|
          l.taught_by?(pe.covered_staff_id) &&
            l.period_time.starts_at == @starts_at &&
            l.period_time.ends_at   == @ends_at
        }
        if matches.size == 1
          @covered_staff_id  = pe.covered_staff_id
          @covered_staff_name  = pe.covered_staff_name
          @schedule_entry = matches[0]
          @lesson_source_hash = @schedule_entry.source_hash
          @staff_covered      = MIS_Staff.by_name(@covered_staff_name)
          pe.used = true
          break;
        end
      end
    end
    unless @covered_staff_id || loader.options.quiet
      puts "Unable to find match for cover ID #{@cover_id}."
      puts "Covering: #{@covering_staff_name} (id #{@covering_staff_id})"
      puts "Timing: #{@starts_at} - #{@ends_at} on #{@task_start.strftime("%d/%m/%Y")}."
      puts "#{plausible_entries.count} plausible entries."
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
          puts "Staff member #{@covering_staff_name}, ID: #{@covering_staff_id} not found to do cover #{@cover_id}."
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
    #@cover_id
    #
    #  And back again - turns out the ID is not unique.  Can't use
    #  covering_staff_id though.  Need to use covered_staff_id instead.
    #
    ((((@cover_id << 8) + @covered_staff_id) << 8) + (@task_start.seconds_since_midnight / 60).to_i) & 0x7fffffff
  end

  def self.construct(loader, mis_data)
    covers = Array.new
    dropped_count = 0
    mis_covers = mis_data[:cover_records]
    mis_cover_needs = mis_data[:cover_needed_records]
    if mis_covers && mis_cover_needs
      mis_covers.each do |record|
        other_records = mis_cover_needs[record.cover_id]
        if other_records
          cover = MIS_Cover.new(loader, record, other_records)
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
    if loader.options.dump_covers
      puts "Dumping #{covers.count} covers"
      covers.each do |cover|
        puts "Cover id #{cover.source_id}"
        puts "  On: #{cover.date.strftime("%d/%m/%Y")}"
        puts "  Doing cover: #{cover.staff_covering.name}"
        puts "  Being covered: #{cover.staff_covered.name}"
      end
      exit
    end
    covers
  end

end

