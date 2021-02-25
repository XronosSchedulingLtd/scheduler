# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module Adhoc
  extend ActiveSupport::Concern

  def id_suffix
    case self
    when AdHocDomainCycle
      "c#{self.id}"
    when AdHocDomainSubject
      "u#{self.id}"
    when AdHocDomainStaff
      "t#{self.id}"
    when AdHocDomainPupilCourse
      "p#{self.id}"
    else
      "XX"
    end
  end

end
