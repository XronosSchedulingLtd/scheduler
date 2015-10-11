# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
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

  def tutorgroup_name
    if Setting.current_era
      #
      #  We go for his tutor group as at today, unless we are outside the
      #  current academic year, in which case we go for one extremity or
      #  other of the year.
      #
      as_at = Date.today
      if as_at < Setting.current_era.starts_on
        as_at = Setting.current_era.starts_on
      elsif as_at > Setting.current_era.ends_on
        as_at = Setting.current_era.ends_on
      end
      tutorgroup = self.tutorgroups(as_at)[0]
      if tutorgroup
        tutorgroup.name
      else
        "Pupil"
      end
    else
      "Pupil"
    end
  end

  def element_name
    #
    #  A constructed name to pass to our element record.  Sensitive to what
    #  our current era is.
    #
    "#{self.name} (#{self.tutorgroup_name})"
  end

  def tabulate_name(columns)
    if columns == 3
      "<tr><td>#{self.known_as}</td><td>#{self.surname}</td><td>#{self.tutorgroup_name}</td></tr>".html_safe
    else
      "<tr><td colspan='#{columns}'>#{self.element_name}</td></tr>".html_safe
    end
  end

  #
  #  Returns the current year group for this pupil, using whatever
  #  numbering convention is in use.  The crucial thing is that start_year
  #  should give the year in which this pupil would have started in your
  #  year 1.
  #
  def year_group
    if Setting.current_era
      Setting.current_era.starts_on.year - self.start_year + 1
    else
      0
    end
  end

  def <=>(other)
    result = self.surname <=> other.surname
    if result == 0
      result = self.forename <=> other.forename
    end
    result
  end

  def tutorgroups(date = nil)
    #
    #  Provided you call Element#groups with recurse set to false, it
    #  is implemented as a scope, so I can chain more scopes.
    #
    self.groups(date, false).tutorgroups
#    self.groups(date, false).select {|g| g.persona_type == "Tutorgrouppersona"}
  end

  def teachinggroups(date = nil)
    self.groups(date, false).select {|g| g.persona_type == "Teachinggrouppersona"}
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
