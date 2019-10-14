# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class PASS_PeriodTime
  #
  #  We're overriding the standard implementation here to fix a couple of
  #  wrong times.
  #
  def initialize(textual_period_time)
    splut = textual_period_time.split(" ")
    starts_at = splut[0][0,5]
    ends_at = splut[2][0,5]
    if starts_at == "23:00" && ends_at == "23:30"
      starts_at = "08:30"
      ends_at   = "09:00"
    end
    super(starts_at, ends_at)
  end

  def ends_at=(value)
    @ends_at = value
  end
end

class PASS_ScheduleEntry
  #
  #  We override the hash key for the merging of simultaneous lessons
  #  in order to accommodate CHS's slightly odd naming.
  #
  def hash_key
    #
    #  Starts with GAMES or PE followed by a digit.
    #
    if /\A(GAMES|PE)\d/ =~ @lesson_desc
      #
      #  Chop off the final digit.  Note that although this will make
      #  the names match up, it won't fix the fact that the separate
      #  lessons have different names.  The final name will end up
      #  being that of one of the originals, but it's hard to predict which.
      #
      local_desc = @lesson_desc[0...-1]
    else
      local_desc = @lesson_desc
    end
    "#{local_desc}/#{@period_time.to_s}/#{@day_name}/#{@week_letter}"
  end

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
    to_delete = Array.new
    @entries.each do |entry|
      unless to_delete.include?(entry)
        hash_key = entry.end_time_hash_key
        other_lesson = lesson_hash[hash_key]
        if other_lesson
          #
          #  Got one to merge.  We keep entry, and merge other_lesson
          #  into it.
          #
          entry.period_time.ends_at = other_lesson.period_time.ends_at
          to_delete << other_lesson
          lesson_hash.delete(hash_key)
        end
      end
    end
    #
    #  Only delete from the array at the end because deleting entries
    #  from an array whilst you're iterating through the array really
    #  confuses Ruby.
    #
    @entries -= to_delete
  end
end
