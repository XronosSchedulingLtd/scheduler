class MIS_Pupil

  attr_reader :source_id,
              :datasource_id,
              :name,
              :forename,
              :surname,
              :known_as,
              :email,
              :house_name,
              :nc_year,
              :form_code

  def initialize(record)
    super
    #
    #  It seems logical to use the pupil_id as the single unique
    #  identifier for each pupil.  Unfortunately, Pass changes the
    #  pupil_id of each pupil each year.  To achieve continuity, we
    #  need to use the name_id, which does at least appear to be
    #  constant.
    #
    @source_id         = record.name_id
    @datasource_id     = @@primary_datasource_id
    if record.preferred_name.blank?
      @forename = record.first_names.split(" ")[0]
    else
      @forename = record.preferred_name
    end
    @surname           = record.surname
    @name              = "#{@forename} #{@surname}"
    @email             = ""
    @house_name        = record.academic_house_description
    @form_code         = record.form_code
    house = MIS_House.by_name(@house_name)
    if house
      house.note_pupil(self)
    end
    #
    #  How to interpret the year group is school-specific.
    #
    if record.form_year.blank?
      puts "Pupil #{@name} has no year group in Pass."
    end
    @nc_year           = translate_year_group(record.form_year)
  end

  def active
    true
  end

  def current
    true
  end

  def ahead
    self.class.ahead
  end

  def self.construct(loader, mis_data)
    @ahead = loader.options.ahead
    pupils = Array.new
    mis_data[:pupils_by_id].values.each do |record|
      pupils << MIS_Pupil.new(record)
    end
    pupils
  end

  def self.ahead
    @ahead
  end
end
