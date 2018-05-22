class MIS_Staff

  attr_reader :source_id,
              :datasource_id,
              :name,
              :forename,
              :surname,
              :title,
              :initials,
              :email,
              :formal_name

  def initialize(record)
    #
    #  Don't have a proper source of staff names yet so we'll kind
    #  of busk it for now.
    #
    #  TODO: Get a proper extraction of staff information from Pass.
    #
    @source_id          = record.staff_id
    @datasource_id      = @@primary_datasource_id
    @formal_name        = record.tutor
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
      #
      #  We are fairly confident that we have the surname first,
      #  but it will be all caps.  Try a slightly clever way to get
      #  it correctly capitalized.
      #
      caps_surname = splut[0]
      regex = Regexp.new(caps_surname, "i")
      offset = informal_salutation =~ regex
      if offset
        surname = informal_salutation[offset, caps_surname.size]
      else
        surname = caps_surname.capitalize
      end
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
