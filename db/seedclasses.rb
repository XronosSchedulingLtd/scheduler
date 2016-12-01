
#
#  A basic set of event category properties, from which we will do
#  some modifications.  It's the modifications which are interesting.
#
class ECH < Hash
  def initialize(values)
    super()
    self[:schoolwide]  = false
    self[:publish]     = true
    self[:unimportant] = false
    self[:can_merge]   = false
    self[:can_borrow]  = false
    self[:compactable] = true
    self[:deprecated]  = false
    self[:privileged]  = false
    self[:visible]     = true
    self.merge!(values)
  end
end

class SeedProperty
  def initialize(name)
    @dbrecord = Property.create!({name: name})
    @dbrecord.reload
  end

  def element_id
    @dbrecord.element.id
  end

  def set_preferred_colour(colour)
    @dbrecord.element.preferred_colour = colour
    @dbrecord.element.save
    self
  end
end


class SeedStaff
  attr_reader :dbrecord, :initials

  def initialize(title, forename, surname, initials)
    @initials = initials
    @dbrecord = Staff.create!({
      name:     "#{forename} #{surname}",
      initials: initials,
      surname:  surname,
      title:    title,
      forename: forename,
      email:    "#{forename.downcase}.#{surname.downcase}@xronos.org",
      active:   true,
      current:  true
    })
    #
    #  Should have acquired an element, so re-load
    #
    @dbrecord.reload
  end

  def element_id
    @dbrecord.element.id
  end

  def teaches(subject)
    @dbrecord.subjects << subject.dbrecord
    self
  end
end


class SeedEvent
  attr_reader :event

  def initialize(eventcategory, eventsource, body, starts_at, ends_at, more = {})
    params = {
      body:             body,
      eventcategory_id: eventcategory.id,
      eventsource_id:   eventsource.id,
      starts_at:        starts_at,
      ends_at:          ends_at
    }
    params.merge!(more)
    @event = Event.create!(params)
  end

  #
  #  Add an attendee to an event.  Must respond to element_id()
  #
  def <<(thing)
    @event.commitments.create!({ element_id: thing.element_id })
  end

  #
  #  Add a collection of things to an event.
  #
  def involving(*params)
    params.each do |p|
      @event.commitments.create!({ element_id: p.element_id })
    end
    self
  end

  def add_note(title, contents, more = {})
    params = {
      title:    title,
      contents: contents,
      visible_guest: false,
      visible_staff: true,
      visible_pupil: false
    }
    params.merge!(more)
    @event.notes.create!(params)
  end
end


class SeedPeriod
  attr_reader :start_time, :end_time

  def initialize(start_time, end_time)
    @start_time = start_time
    @end_time = end_time
  end
end


class SeedLocation

  attr_reader :dbrecord, :aliasrec

  def initialize(name, aliasname = nil, display = true, friendly = true)
    @dbrecord =
      Location.create!({
        name:    name,
        active:  true,
        current: true})
    @dbrecord.reload
    if aliasname
      @aliasrec =
        Locationalias.create!({
          name:          aliasname,
          location_id:   @dbrecord.id,
          display:       display,
          friendly:      friendly})
    else
      @aliasrec = nil
    end
  end

  def element_id
    @dbrecord.element.id
  end

end


class SeedSubject
  attr_reader :dbrecord

  def initialize(name)
    @dbrecord = Subject.create!({name: name, current: true})
    @dbrecord.reload

  end

  def element_id
    @dbrecord.element.id
  end

end


class SeedGroup

  attr_reader :dbrecord, :subject, :name

  def initialize(name, era, type = "Vanilla", more = {})
    @name      = name
    @starts_on = era.starts_on
    case type
    when "Teaching"
      baseclass = Teachinggroup
    when "Tutor"
      baseclass = Tutorgroup
    else
      baseclass = Vanillagroup
    end
    params = {
      name:       name,
      starts_on:  era.starts_on,
      era_id:     era.id,
      current:    true
    }
    params.merge!(more)
    @dbrecord = baseclass.create!(params)
    @dbrecord.reload
  end

  def element_id
    @dbrecord.element.id
  end

  def <<(new_member)
    @dbrecord.add_member(new_member.dbrecord, @starts_on)
  end

  #
  #  Add a whole lot of members in one go.
  #
  def members(*params)
    params.each do |p|
      @dbrecord.add_member(p.dbrecord, @starts_on)
    end
    self
  end

end

class SeedTeachingGroup < SeedGroup
  def initialize(name, era, subject)
    @subject   = subject
    super(name, era, "Teaching", {subject_id: subject.dbrecord.id})
  end
end

class SeedTutorGroup < SeedGroup
  def initialize(yeargroup, era, staff, house)
    name = "#{yeargroup}/#{staff.initials}"
    start_year = era.starts_on.year - yeargroup + 1
    super(name, era, "Tutor", {house: house,
                               staff_id: staff.dbrecord.id,
                               start_year: start_year})
  end
end

class SeedPupil

  FORENAMES = ["Peter",
               "John",
               "Charles",
               "Albert",
               "Freddie",
               "James",
               "Matthew",
               "Michael",
               "Claire",
               "Christine",
               "Mila",
               "Stephen",
               "Mark",
               "Luke",
               "Robert",
               "Richard",
               "Lucy",
               "Eva",
               "Millie",
               "William",
               "Mimi",
               "Olivia",
               "Wayne",
               "Sharon",
               "Kumar",
               "Oscar",
               "Jack",
               "Sean"]
  SURNAMES = ["Smith",
              "Jones",
              "Stone",
              "Robinson",
              "Jennings",
              "Darbishire",
              "Kerrigan",
              "Fountain",
              "Simmons",
              "Storey",
              "Warburton",
              "O'Hickey",
              "West",
              "Descartes",
              "Loddon",
              "Green",
              "Brown",
              "Temple",
              "Binns",
              "Fotheringay-Smith",
              "Cotton",
              "O'Doherty",
              "Poon",
              "Coull",
              "Morgan",
              "Evans",
              "Flanagan",
              "Dinsey",
              "Spence",
              "Davies",
              "Lowndes",
              "Nelson",
              "Cameron",
              "Enderton",
              "Wodehouse",
              "Drake",
              "Gerrard",
              "Collins",
              "Greenwood",
              "Hurley",
              "Hickson",
              "Thompson",
              "Grant",
              "Laurie",
              "Lansden",
              "Lee"
  ]

  attr_reader :dbrecord

  def initialize(era, yeargroup)
    forename = FORENAMES.sample
    surname = SURNAMES.sample
    start_year = era.starts_on.year - yeargroup + 1
    @dbrecord = Pupil.create!({
      name:     "#{forename} #{surname}",
      surname:  surname,
      forename: forename,
      known_as: forename,
      email:    "#{forename.downcase}.#{surname.downcase}@pupils.xronos.uk",
      start_year: start_year,
      current:    true
    })
    @dbrecord.reload
  end

  def element_id
    @dbrecord.element.id
  end

end


class SeedLesson < SeedEvent


  def self.lessoncategory
    unless @lessoncategory
      @lessoncategory = Eventcategory.find_by(name: "Lesson")
      unless @lessoncategory
        raise "Can't find the lesson event category."
      end
    end
    @lessoncategory
  end

  def lessoncategory
    self.class.lessoncategory
  end

  #
  #  All parameters should themselves be Seed<Something> objects.
  #  We get the subject for the lesson from the group.
  #
  def initialize(eventsource, staff, group, location, day, period, more = {})
    #
    #  First let's create the event itself.
    #
    starts_at = Time.zone.parse("#{day.to_s} #{period.start_time}")
    ends_at   = Time.zone.parse("#{day.to_s} #{period.end_time}")
    super(lessoncategory, eventsource, group.name, starts_at, ends_at, more)
    #
    #  Needs:
    #
    #    Member of staff
    #    Group
    #    Location
    #    Subject
    #
    self << staff
    self << group
    self << location
    if group.subject
      self << group.subject
    end
    @event.reload
  end

  def covered_by(staff)
    commitment = @event.commitments.first
    @event.commitments.create!({ element_id: staff.element_id,
                                 covering_id: commitment.id })
    self
  end

end


class SeedMeeting < SeedEvent

  def self.meetingcategory
    unless @meetingcategory
      @meetingcategory = Eventcategory.find_by(name: "Meeting")
      unless @meetingcategory
        raise "Can't find the meeting event category."
      end
    end
    @meetingcategory
  end

  def meetingcategory
    self.class.meetingcategory
  end

  #
  #  All parameters should themselves be Seed<Something> objects.
  #  We get the subject for the lesson from the group.
  #
  def initialize(eventsource, title, staff, location, day, period)
    #
    #  First let's create the event itself.
    #
    starts_at = Time.zone.parse("#{day.to_s} #{period.start_time}")
    ends_at   = Time.zone.parse("#{day.to_s} #{period.end_time}")
    super(meetingcategory, eventsource, title, starts_at, ends_at)
    if staff.respond_to?(:each)
      staff.each do |s|
        self << s
      end
    else
      self << staff
    end
    self << location
    @event.reload
  end

end

