class MIS_Pupil
  SELECTOR = "PupilManager CurrentPupils Pupil"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,  :attribute, :integer],
    IsamsField["SchoolCode",         :sb_id,     :data,      :integer],
    IsamsField["Initials",           :initials,  :data,      :string],
    IsamsField["Title",              :title,     :data,      :string],
    IsamsField["Forename",           :forename,  :data,      :string],
    IsamsField["Surname",            :surname,   :data,      :string],
    IsamsField["EmailAddress",       :email,     :data,      :string],
    IsamsField["NCYear",             :nc_year,   :data,      :integer],
    IsamsField["Fullname",           :full_name, :data,      :string],
    IsamsField["Preferredname",      :known_as,  :data,      :string],
    IsamsField["Form",               :form_name, :data,      :string],
    IsamsField["AcademicHouse",      :house,     :data,      :string]
  ]

  include Creator

  attr_reader :name, :datasource_id, :current

  def initialize(entry)
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

  def source_id
    @isams_id
  end

  def alternative_find_hash
    {
      :source_id => @sb_id,
      :datasource_id => @@secondary_datasource_id
    }
  end

  #
  #  In what year would this pupil have started in the 1st year (NC year 7).
  #  Calculated from his current year group, plus the current academic
  #  year.
  #
  def effective_start_year(era)
    era.starts_on.year + 7 - self.nc_year
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data)
  end
end
