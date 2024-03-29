#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Pupil < ApplicationRecord

  validates :name, presence: true

  include Elemental

  #
  #  Override this method inherited from Elemental.
  #
  def self.a_person?
    true
  end

  belongs_to :datasource, optional: true

  self.per_page = 15

  scope :current, -> { where(current: true) }

  def active
    true
  end

  #
  #  Method to find and cache this student's tutor group.
  #
  def tutorgroup
    unless @tutorgroup
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
        @tutorgroup = self.tutorgroups(as_at)[0]
      end
    end
    @tutorgroup
  end

  def tutorgroup_name
    self.tutorgroup ? self.tutorgroup.name : (self.current ? "Pupil" : "Ex pupil")
  end

  def tutor_name
    self.tutorgroup ? self.tutorgroup.staff.name : "Unknown"
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

  def csv_name
    [self.known_as,
     self.surname,
     self.tutorgroup_name,
     self.email].to_csv
  end

  #
  #  Returns the current year group for this pupil, using whatever
  #  numbering convention is in use.  The crucial thing is that start_year
  #  should give the year in which this pupil would have started in your
  #  year 1.
  #
  def year_group(in_era = Setting.current_era)
    if in_era && self.start_year
      in_era.starts_on.year - self.start_year + 1
    else
      0
    end
  end

  #
  #  Provide a one-line description of this pupil for display purposes.
  #
  #  Objective is:
  #
  #  A 5th year pupil in Philpott's House - tutor: JHW
  #
  def description_line
    if Setting.ordinalize_years?
      year_bit = "#{year_group.ordinalize} year"
    else
      year_bit = "year #{year_group}"
    end
    "A #{year_bit} pupil in #{
      self.house_name.blank? ? "Unknown" : self.house_name
    } House.  #{Setting.tutor_name}: #{self.tutor_name}."
  end

  #
  #  The next two methods exist in order to cope explicitly
  #  with nil fields in either our record or the other one.
  #
  def compare_year(other)
    if self.start_year.nil?
      if other.start_year.nil?
        0
      else
        1
      end
    else
      if other.start_year.nil?
        -1
      else
        other.start_year <=> self.start_year
      end
    end
  end

  def compare_names(own, other)
    if own.blank?
      if other.blank?
        0
      else
        -1
      end
    else
      if other.blank?
        1
      else
        own <=> other
      end
    end
  end

  def <=>(other)
    #
    #  Any of the sorting criteria fields might be nil.  We still
    #  need to return a sensible result.
    #
    #  Nil year puts you at the end.
    #  Nil or empty name at the beginning.
    #
    #  Realistically, none of them should be nil, but it's not
    #  an actual constraint so we need to cope.
    #
    result = sort_by_entity_type(other)
    if result == 0
      #
      #  By this point we do at least know that the other entity
      #  is of the same type as us, and therefore also a pupil.
      #
      result = compare_year(other)
      if result == 0
        result = compare_names(self.surname, other.surname)
        if result == 0
          result = compare_names(self.forename, other.forename)
        end
      end
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

  #
  #  Another one, to move house information into the pupil record.
  #
  def import_house
    if self[:house_name].blank? && !self.tutorgroup.nil?
      self.house_name = self.tutorgroup.house
      self.save
    end
  end

  def self.import_houses
    Pupil.find_each do |p|
      p.import_house
    end
  end

end
