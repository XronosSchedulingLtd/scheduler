class MIS_Staff
  SELECTOR = "HRManager CurrentStaff StaffMember"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id, :integer],
    IsamsField["PreviousMISId",      :sb_id,    :integer],
    IsamsField["Initials",           :initials, :string],
    IsamsField["Title",              :title,    :string],
    IsamsField["Forename",           :forename, :string],
    IsamsField["Surname",            :surname,  :string],
    IsamsField["SchoolEmailAddress", :email,    :string],
    IsamsField["FullName",           :name,     :string]
  ]

  DB_CLASS = Staff
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :active,
                      :current,
                      :teaches,
                      :does_cover]
  FIELDS_TO_UPDATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :current,
                      :teaches,
                      :does_cover]

  include Creator

  def initialize(entry)
    do_initialize(entry)
  end

  def adjust
    #
    #  We can perhaps improve the SB data a little?
    #
    if self.name.blank? && !(self.surname.blank? && self.forename.blank?)
      self.name = "#{self.forename} #{self.surname}"
    end
    #
    #  Whoever enters e-mail address into SB puts in random capitalisation.
    #  Take it out again.
    #
    unless self.email.blank?
      self.email.downcase!
    end
    #
    #  We don't really know which of the ones we get from SB are valid
    #  and which aren't.  We take an initial stab at it.
    #
    self.active = !!(self.email =~ /\@abingdon\.org\.uk$/)
    self.current = (self.left != 1)
    self.teaches = (self.teacher == 1)
    self.does_cover = (self.cover == 1)
  end

  def source_id(secondary = false)
    if secondary
      @sb_id
    else
      @isams_id
    end
  end

end

