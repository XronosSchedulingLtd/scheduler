# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class Subject < ActiveRecord::Base

  DISPLAY_COLUMNS = [:subject_teachers, :subject_groups, :dummy]

  include Elemental

  has_many :teachinggrouppersonae, :dependent => :nullify

  has_and_belongs_to_many :staffs
  before_destroy { staffs.clear }

  scope :current, -> { where(current: true) }

  def teachinggroups
    self.teachinggrouppersonae.preload(:group).collect { |tgp| tgp.group }
  end

  def active
    true
  end

  def element_name
    self.name
  end

  def show_historic_panels?
    false
  end

  #
  #  Deleting a subject with dependent stuff could be disastrous.
  #  Major loss of information.  Allow deletion only if we have no
  #  commitments.
  #
  def can_destroy?
    self.element.commitments.count == 0
  end

end