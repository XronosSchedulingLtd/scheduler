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
    #
    #  Don't have a proper source of pupil names yet so we'll kind
    #  of busk it for now.
    #
    #  TODO: Get a proper extraction of pupil information from Pass.
    #
    @source_id     = record.pupil_id
    @datasource_id = @@primary_datasource_id
    @forename      = "Pupil"
    @surname       = "Number #{record.pupil_id}"
    @name          = "#{@forename} #{@surname}"
    @email         = ""
    @nc_year       = guess_nc_year(record.set_code)
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
    pupils_by_id = Hash.new
    mis_data[:timetable_records].each_with_index do |record, index|
      if record.pupil_id
        pupils_by_id[record.pupil_id] ||= MIS_Pupil.new(record)
      end
    end
    pupils_by_id.values
  end

  def self.ahead
    @ahead
  end
end
