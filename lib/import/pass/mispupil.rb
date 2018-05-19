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
    @source_id         = record.pupil_id
    @datasource_id     = @@primary_datasource_id
    @forename          = "Pupil"
    @surname           = "Number #{record.pupil_id}"
    @name              = "#{@forename} #{@surname}"
    @email             = ""
    @possible_nc_years = Array.new
  end

  def note_record(record)
    @possible_nc_years << guess_nc_year(record.set_code)
  end

  def calculate_nc_year
#    puts "Entering calculate_nc_year"
#    puts "Possible nc years: #{@possible_nc_years}"
    #
    #  We have an array containing various guesses at our NC year.
    #  Go with the majority.
    #
    @nc_year = @possible_nc_years.compact.
                                  group_by {|n| n}.
                                  values.
                                  max_by(&:size).
                                  first
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
        (pupils_by_id[record.pupil_id] ||= MIS_Pupil.new(record)).note_record(record)
      end
    end
    #
    #  Now give each pupil the chance to work out his or her most likely
    #  national curriculum year.
    #
    pupils_by_id.each do |id, pupil|
      pupil.calculate_nc_year
    end
    pupils_by_id.values
  end

  def self.ahead
    @ahead
  end
end
