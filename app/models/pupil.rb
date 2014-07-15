# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Pupil < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  self.per_page = 15

  scope :current, -> { where(current: true) }

  def active
    true
  end

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.name} (Pupil)"
  end

  def <=>(other)
    result = self.surname <=> other.surname
    if result == 0
      result = self.forename <=> other.forename
    end
    result
  end

  def tutorgroups(date = nil)
    self.groups(date, false).select {|g| g.class == Tutorgroup}
  end

  def teachinggroups(date = nil)
    self.groups(date, false).select {|g| g.class == Teachinggroup}
  end

  #
  #  A temporary maintenance method.
  #
  def self.set_all_current
    count = 0
    Pupil.all.each do |p|
      unless p.current
        p.current = true
        p.save
        count += 1
      end
    end
    puts "Amended #{count} pupil records."
    nil
  end

end
