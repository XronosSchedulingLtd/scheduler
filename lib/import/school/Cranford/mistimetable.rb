# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class PASS_PeriodTime
  def ends_at=(value)
    @ends_at = value
  end
end

class PASS_ScheduleEntry
  #
  #  We want to merge lessons with the same name, staff and rooms
  #  which happen consecutively.  One finishes just as the next one
  #  starts.
  #

  def time_hash_key(time)
    "#{@lesson_desc}/#{time}/#{@day_name}/#{@week_letter}/#{
      @staff_ids.join(",")
    }/#{
      @room_ids.join(",")
    }"
  end

  def start_time_hash_key
    time_hash_key(@period_time.starts_at)
  end

  def end_time_hash_key
    time_hash_key(@period_time.ends_at)
  end

end

class MIS_Schedule
  def local_processing
    #
    #  We may well modifiy @entries
    #
    lesson_hash = Hash.new
    @entries.each do |entry|
      hash_key = entry.start_time_hash_key
      if lesson_hash[hash_key]
        LOG_Debug("Odd - duplicate lesson start time hash key")
        LOG_Debug(hash_key)
      end
      lesson_hash[hash_key] = entry
    end
    #
    #  And now look for consecutives.
    #
    @entries.each do |entry|
      hash_key = entry.end_time_hash_key
      other_lesson = lesson_hash[hash_key]
      if other_lesson
        #
        #  Got one to merge.  We keep entry, and merge other_lesson
        #  into it.
        #
        entry.period_time.ends_at = other_lesson.period_time.ends_at
        @entries.delete(other_lesson)
        lesson_hash.delete(hash_key)
      end
    end

  end
end
