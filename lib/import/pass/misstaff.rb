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
    @source_id          = record.staff_id
    @datasource_id      = @@primary_datasource_id
    @forename, @surname = split_name(record.tutor, record.informal_salutation)
    @name               = "#{@forename} #{@surname}"
    @title              = record.label_salutation.partition(" ").first
    @initials           = "#{@forename[0].upcase}#{@surname[0].upcase}"
    @email              = construct_email(forename, surname)
  end

  def split_name(tutor, informal_salutation)
    #
    #  We don't get the forename and surname separately, so we try
    #  to split up the whole name.  Try for the tutor field first.
    #
    splut = tutor.split(",")
    if splut.size == 2
      surname = splut[0].capitalize
      forename = splut[1].strip
    else
      splut = informal_salutation.split(" ")
      surname = splut.pop
      if splut.size > 0
        forename = splut.join(" ")
      else
        forename = "<Unknown>"
      end
    end
    [forename, surname]
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
