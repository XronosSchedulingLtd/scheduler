require 'yaml'

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

  def from_pass(record)
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
    self
  end

  def from_yaml(record, datasource_id)
    @datasource_id = datasource_id
    @source_id     = record["source_id"]
    @formal_name   = record["formal_name"]
    @forename      = record["forename"]     || "Unknown"
    @surname       = record["surname"]      || "Unknown"
    @title         = record["title"]        || ""
    @initials      = record["initials"]     || ""
    @email         = record["email"]        || ""
    @name          = "#{@forename} #{@surname}"
    self
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

  def self.from_pass(record)
    MIS_Staff.new.from_pass(record)
  end

  def self.from_yaml(record, datasource_id)
    MIS_Staff.new.from_yaml(record, datasource_id)
  end

  def self.construct(loader, mis_data)
    @staff_by_name = Hash.new
    staff_by_id = Hash.new
    mis_data[:timetable_records].each do |record|
      staff_by_id[record.staff_id] ||= MIS_Staff.from_pass(record)
    end
    #
    #  Can we get any extra staff records?  Need a suitable datasource
    #  first.
    #
    extra_staff = Array.new
    yaml_datasource = Datasource.find_by(name: "Yaml")
    if yaml_datasource
      begin
        extra_staff_records =
          YAML.load(
            File.open(Rails.root.join('import/pass/Extra', 'staff.yml'))
        )
        extra_staff_records.each do |record|
          extra_staff << MIS_Staff.from_yaml(record, yaml_datasource.id)
        end
      rescue Errno::ENOENT
        #
        #  If there's no file, then we simply don't load it.
        #
      end
    end
    @staff_by_name = Hash.new
    staff_by_id.each do |id, staff|
      @staff_by_name[staff.formal_name] = staff
    end
    extra_staff.each do |staff|
      @staff_by_name[staff.formal_name] = staff
    end
    staff_by_id.values + extra_staff
  end

  def self.by_name(name)
    @staff_by_name[name]
  end

end
