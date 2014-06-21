# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Era < ActiveRecord::Base

  has_many :teachinggroups, dependent: :destroy
  has_many :tutorgroups, dependent: :destroy

end
