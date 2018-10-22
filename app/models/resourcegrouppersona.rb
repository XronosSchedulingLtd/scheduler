# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Resourcegrouppersona < ActiveRecord::Base

  include Persona

  self.per_page = 15

  def active
    true
  end

  def user_editable?
    true
  end

  def can_have_requests?
    true
  end

  def add_directly?
    true
  end
end
