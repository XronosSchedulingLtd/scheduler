class MIS_Pupil
  SELECTOR = "PupilManager CurrentPupils Pupil"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,   :attribute, :integer],
    IsamsField["SchoolCode",         :school_code,:data,      :string],
    IsamsField["SchoolId",           :school_id,  :data,      :string],
    IsamsField["Initials",           :initials,   :data,      :string],
    IsamsField["Title",              :title,      :data,      :string],
    IsamsField["Forename",           :forename,   :data,      :string],
    IsamsField["Surname",            :surname,    :data,      :string],
    IsamsField["EmailAddress",       :email,      :data,      :string],
    IsamsField["NCYear",             :nc_year,    :data,      :integer],
    IsamsField["Fullname",           :full_name,  :data,      :string],
    IsamsField["Preferredname",      :known_as,   :data,      :string],
    IsamsField["Form",               :form_name,  :data,      :string],
    IsamsField["AcademicHouse",      :academic_house_name, :data, :string],
    IsamsField["BoardingHouse",      :boarding_house_name, :data, :string]
  ]

  include Creator

  attr_reader :name, :datasource_id, :current, :house, :sb_id, :house_name

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
    if @academic_house_name.blank?
      @house_name = @boarding_house_name
    else
      @house_name = @academic_house_name
    end
    @house = MIS_House.by_name(@house_name)
    #
    #  This isn't really right, but unfortunately Niki has overwritten
    #  the previous MIS ID field with a new value.
    #
    @sb_id = @isams_id
  end

  def wanted
    @nc_year && local_wanted(@nc_year)
  end

  def source_id
    @isams_id
  end

  def alternative_find_hash
    if do_convert
      {
        :source_id => @sb_id,
        :datasource_id => @@secondary_datasource_id
      }
    else
      nil
    end
  end

  def ahead
    self.class.ahead
  end

  def do_convert
    self.class.do_convert
  end

  def check_idents
    if self.isams_id != self.sb_id
      puts "Pupil has isams id #{self.isams_id} and SB id #{self.sb_id}."
    end
  end

  def self.construct(loader, isams_data)
    @ahead = loader.options.ahead
    @do_convert = loader.options.do_convert
    records = self.slurp(isams_data.xml)
    if loader.options.do_check
      records.each do |rec|
        rec.check_idents
      end
    end
    records
  end

  def self.ahead
    @ahead
  end

  def self.do_convert
    @do_convert
  end
end
