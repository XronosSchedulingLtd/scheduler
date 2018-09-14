# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class MIS_Cover
  #
  #  Because of having merged half-lessons in the import from Pass,
  #  we relax the matching criteria for cover slots slightly.
  #
  #

  def suitable_match?(pe, lesson)
    lesson.taught_by?(pe.covered_staff_id) &&
      lesson.period_time.starts_at == @starts_at &&
      #
      #  What the timetable entries call a SET_CODE, the cover
      #  entries call a TASK_CODE.  This is Pass being silly,
      #  not Scheduler.
      #
      lesson.set_code              == pe.task_code
  end

end
