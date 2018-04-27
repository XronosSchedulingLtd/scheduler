class MIS_Staff

  attr_reader :source_id,
              :datasource_id,
              :name,
              :forename,
              :surname,
              :title,
              :initials,
              :email

  def initialize(record)
    #
    #  Don't have a proper source of staff names yet so we'll kind
    #  of busk it for now.
    #
    #  TODO: Get a proper extraction of staff information from Pass.
    #
    @source_id     = record.staff_id
    @datasource_id = @@primary_datasource_id
    @forename      = record.staff_forename
    @surname       = record.staff_surname.capitalize
    @name          = "#{@forename} #{@surname}"
    @title         = record.label_salutation.partition(" ").first
    @initials      = "#{@forename[0].upcase}#{@surname[0].upcase}"
    @email         = construct_email(forename, surname)
  end

  def active
    true
  end

  def current
    true
  end

  def self.construct(loader, mis_data)
    staff_by_id = Hash.new
    mis_data[:timetable_records].each do |record|
      staff_by_id[record.staff_id] ||= MIS_Staff.new(record)
    end
    staff_by_id.values
  end
end
