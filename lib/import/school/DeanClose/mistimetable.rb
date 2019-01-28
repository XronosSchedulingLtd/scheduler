# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#  A design error in the iSAMS API means that it is not possible
#  properly to reconstruct the timetable if it involves Teaching Forms.
#  A certain amount of workaround code has been written to try to
#  retrieve the situation, but it inevitably involves some hard-coded
#  information specific to the school.
#
#  Dean Close don't use Teaching Forms, so disable all the relevant
#  entries.
#
class ISAMS_TimetableEntry
  def wanted
    #
    #  We want only timetable entries which involve an explicit
    #  Teaching Set (as opposed to a Teaching Form).
    #
    self.set_id == 1
  end
end

class ISAMS_MissingGroup
  def wanted
    #
    #  We don't want to attempt to reconstruct any of the missing
    #  Teaching Forms.
    #
    false
  end
end
