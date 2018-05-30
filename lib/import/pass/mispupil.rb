class MIS_Pupil

  attr_reader :source_id,
              :datasource_id,
              :name,
              :forename,
              :surname,
              :known_as,
              :email,
              :nc_year

  def initialize(record)
    @source_id         = record.pupil_id
    @datasource_id     = @@primary_datasource_id
    if record.preferred_name.blank?
      @forename = record.first_names.split(" ")[0]
    else
      @forename = record.preferred_name
    end
    @surname           = record.surname
    @name              = "#{@forename} #{@surname}"
    @email             = ""
    #
    #  How to interpret the year group is school-specific.
    #
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
