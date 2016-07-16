# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Taggrouppersona < ActiveRecord::Base

  include Persona

  self.per_page = 15

  def active
    true
  end

  def user_editable?
    if group.datasource.name == Setting.current_mis
      false
    else
      true
    end
  end
end
