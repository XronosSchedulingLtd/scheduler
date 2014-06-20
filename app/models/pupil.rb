class Pupil < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  self.per_page = 15

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

end
