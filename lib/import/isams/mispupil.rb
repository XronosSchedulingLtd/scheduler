class MIS_Pupil
  SELECTOR = "PupilManager CurrentPupils Pupil"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,  :integer],
    IsamsField["SchoolCode",         :sb_id,     :integer],
    IsamsField["Initials",           :initials,  :string],
    IsamsField["Title",              :title,     :string],
    IsamsField["Forename",           :forename,  :string],
    IsamsField["Surname",            :surname,   :string],
    IsamsField["EmailAddress",       :email,     :string],
    IsamsField["NCYear",             :nc_year,   :integer],
    IsamsField["Fullname",           :full_name, :string],
    IsamsField["Preferredname",      :known_as,  :string]
  ]

  DB_CLASS = Pupil
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :current,
    :datasource_id
  ]

  FIELDS_TO_UPDATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :current
  ]

  include Creator

  attr_reader :name, :datasource_id

  def initialize(entry)
    do_initialize(entry)
    #
    #  These two are used if a new d/b record is created.
    #
    @current = true
    @datasource_id = @@primary_datasource_id
    super
  end

  def adjust
    @email.downcase!
    @name = "#{@known_as} #{@surname}"
  end

  def wanted
    @nc_year && @nc_year < 20
  end

  def source_id(secondary = false)
    if secondary
      @sb_id
    else
      @isams_id
    end
  end

  #
  #  In what year would this pupil have started in the 1st year (NC year 7).
  #  Calculated from his current year group, plus the current academic
  #  year.
  #
  def effective_start_year(era)
    era.starts_on.year + 7 - self.nc_year
  end

end
