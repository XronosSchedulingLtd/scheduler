# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Service < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  def active
    true
  end

  def element_name
    name
  end

  def owners_initials
    self.element.owners.collect {|o| o.initials}.join(", ")
  end

  #
  #  Deleting a service with dependent stuff could be disastrous.
  #  Major loss of information.  Allow deletion only if we have no
  #  commitments.
  #
  def can_destroy?
    self.element.commitments.count == 0
  end

end
