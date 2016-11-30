# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create!([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create!(name: 'Emanuel', city: cities.first)

#
#  Always set everything to the current week.
#
Date.beginning_of_week = :sunday
sunday = Date.today.at_beginning_of_week
monday    = sunday + 1.day
tuesday   = sunday + 2.days
wednesday = sunday + 3.days
thursday  = sunday + 4.days
friday    = sunday + 5.days
saturday  = sunday + 6.days

#
#  What academic year are we notionally in?
#
today = Date.today
current_year = today.year
era_start_date = Date.parse("#{current_year}-08-15")
if era_start_date > today
  era_start_date = era_start_date - 1.year
end
era_end_date = era_start_date + 1.year - 1.day
#puts era_start_date
#puts era_end_date
era_short_name = "#{era_start_date.strftime("%Y")}/#{era_end_date.strftime("%y")}"
era_name = "Academic Year #{era_short_name}"

#
#  If there are any left over from previous runs, then my arrays don't
#  contain the necessary IDs.  Start with a clean slate.
#
Location.destroy_all
Note.destroy_all
Commitment.destroy_all
Event.destroy_all
Staff.destroy_all
Property.destroy_all
Eventsource.destroy_all
Datasource.destroy_all
Eventcategory.destroy_all
#Setting.destroy_all  You can't delete them.
Era.destroy_all

#
#  It's not quite a clean slate, because the IDs carry on incrementing
#  from where they were, but at least everything is consistent.
#

#
#  Need a current era, which we'll assume to be the current academic year.
#  For reasons of overlap, these default to running from 15th August in
#  one year, to 14th August of the next.
#

current_era = Era.create!({
  name:       era_name,
  starts_on:  era_start_date,
  ends_on:    era_end_date,
  short_name: era_short_name
})

perpetual_era = Era.create!({
  name:       "Perpetual",
  starts_on:  era_start_date,
  ends_on:    nil,
  short_name: "Perpetual"
})

#
#  This one may well fail, but we don't care.
#
Setting.create({
  current_era_id: current_era.id,
  perpetual_era_id: perpetual_era.id,
  enforce_permissions: true,
  auth_type: 1
})

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

#
#  First, some which are intrinsic to the functioning of the system.
#
weeklettercategory = Eventcategory.create!([
  ECH.new({name: "Lesson"}),
  ECH.new({name: "Week letter", schoolwide: true, privileged: true }),
  ECH.new({name: "Duty", privileged: true}),
  ECH.new({name: "Invigilation", privileged: true})
])

Property.create!({name: "Calendar"})

#
#  And the rest fall under a heading of likely to be useful.
#

#
#  Privileged event categories can be used by nominated users only.
#
privilegedeventcategories = Eventcategory.create!([
  ECH.new({name: "Date - crucial", schoolwide: true, privileged: true }),
  ECH.new({name: "Hidden", publish: false, visible: false, privileged: true}),
  ECH.new({name: "Parents' evening", privileged: true}),
  ECH.new({name: "Reporting deadline", privileged: true}),
  ECH.new({name: "Tutor period", privileged: true}),
  ECH.new({name: "Assembly", privileged: true})
])


eventcategories = Eventcategory.create!([
  ECH.new({name: "Sports fixture"}),
  ECH.new({name: "Trip"}),
  ECH.new({name: "INSET / Training"}),
  ECH.new({name: "Interview / Audition"}),
  ECH.new({name: "Practice / Rehearsal"}),
  ECH.new({name: "Performance"}),
  ECH.new({name: "Religious service"}),
  ECH.new({name: "Date - other", unimportant: true}),
  ECH.new({name: "Event set-up"}),
  ECH.new({name: "Meeting"})
])

eventsources = Eventsource.create!([
    { name: "Seedfile" },
    { name: "Manual" }
])

thisfile = eventsources[0]

datasource = Datasource.create!({ name: "Seedfile" })

#
#  Everything from here on down is demonstration data.  You probably don't
#  want to load it in a new live system.
#

class SeedStaff
  attr_reader :dbrecord

  def initialize(title, forename, surname, initials)
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

end

sjp = SeedStaff.new("Mr", "Simon", "Philpotts", "SJP")
ced = SeedStaff.new("Mrs", "Claire", "Dunwoody", "CED")
psl = SeedStaff.new("Ms", "Phillipa", "Long", "PSL")
dlj = SeedStaff.new("Mr", "David", "Jones", "DLJ")


calendarelement = Element.find_by(name: "Calendar")
#calendarelement.preferred_colour = "#3cb371"
#calendarelement.preferred_colour = "#00476b"
calendarelement.preferred_colour = "#1f94bc"
calendarelement.save

calendarevents = Event.create!(
  [
    {
      body:             "3rd XV away - St Asaph's",
      eventcategory_id: eventcategories[1].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{wednesday.to_s} 14:00"),
      ends_at:          Time.zone.parse("#{wednesday.to_s} 17:00"),
      organiser_id:     ced.element_id
    },
    {
      body:             "2nd XV home - St Asaph's",
      eventcategory_id: eventcategories[1].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{wednesday.to_s} 14:00"),
      ends_at:          Time.zone.parse("#{wednesday.to_s} 17:00"),
      organiser_id:     ced.element_id
    },
    {
      body:             "Geography field trip",
      eventcategory_id: eventcategories[2].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{thursday.to_s} 09:00"),
      ends_at:          Time.zone.parse("#{thursday.to_s} 17:00"),
      organiser_id:     ced.element_id
    },
    {
      body:             "Year 9 parents' evening",
      eventcategory_id: privilegedeventcategories[2].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{tuesday.to_s} 17:30"),
      ends_at:          Time.zone.parse("#{tuesday.to_s} 21:00"),
      organiser_id:     ced.element_id
    },
    {
      body:             "Rowing at Eton Dorney",
      eventcategory_id: eventcategories[1].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{saturday.to_s} 10:00"),
      ends_at:          Time.zone.parse("#{saturday.to_s} 15:00"),
      organiser_id:     sjp.element_id
    }
  ]
)

calendarevents.each do |ce|
  Commitment.create!(
    {
      event_id:   ce.id,
      element_id: calendarelement.id
    }
  )
end

startofterm = privilegedeventcategories[0].events.create!( {
    body:             "Start of term",
    eventsource_id:   thisfile.id,
    owner_id:         nil,
    starts_at:        Time.zone.parse("#{monday.to_s}"),
    ends_at:          Time.zone.parse("#{tuesday.to_s}"),
    all_day:          true
})

startofterm.commitments.create!({element_id: calendarelement.id })

Commitment.create!(
  {
    event_id: calendarevents[4].id,
    element_id: ced.element_id
  }
)

Note.create!(
  {
    title: "",
    contents: "Please could parents not attempt to take rowers away\nbefore the end of the last event.\n\nRefreshments will be provided in the school marquee.",
    parent_id: calendarevents[4].id,
    parent_type: "Event",
    visible_guest: true,
    visible_staff: true
  }
)

#
#  Now some simple timetable stuff.
#
class SeedPeriod
  attr_reader :start_time, :end_time

  def initialize(start_time, end_time)
    @start_time = start_time
    @end_time = end_time
  end
end

periods = [
  SeedPeriod.new("09:00", "09:25"),         # 0 - Assembly
  SeedPeriod.new("09:25", "10:15"),         # 1
  SeedPeriod.new("10:15", "11:05"),         # 2
  SeedPeriod.new("11:25", "12:15"),         # 3
  SeedPeriod.new("12:15", "13:05"),         # 4
  SeedPeriod.new("14:00", "14:50"),         # 5
  SeedPeriod.new("14:50", "15:40"),         # 6
  SeedPeriod.new("15:40", "16:30")          # 7
]

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

SeedLocation.new("Main Hall")
SeedLocation.new("Genghis Khan Suite", "GKS")
l101 = SeedLocation.new("L101")
l102 = SeedLocation.new("L102")
SeedLocation.new("L103")
SeedLocation.new("L104")
SeedLocation.new("L105")
SeedLocation.new("L106")
SeedLocation.new("L107")
l108 = SeedLocation.new("L108")
SeedLocation.new("L109")
SeedLocation.new("L110")
SeedLocation.new("L111")

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

SeedSubject.new("Drama")
SeedSubject.new("English")
subjectfrench = SeedSubject.new("French")
subjectfm     = SeedSubject.new("Further Maths")
subjectmaths  = SeedSubject.new("Mathematics")
SeedSubject.new("Geography")
SeedSubject.new("German")
SeedSubject.new("History")
SeedSubject.new("Italian")
SeedSubject.new("Latin")
SeedSubject.new("Physical Education")
SeedSubject.new("Spanish")
SeedSubject.new("Sport")

class SeedGroup

  attr_reader :dbrecord, :subject, :name

  def initialize(name, era, subject, type = "Teaching")
    @name    = name
    @subject = subject
    @dbrecord = Teachinggroup.create!({
      name:       name,
      starts_on:  era.starts_on,
      era_id:     era.id,
      subject_id: subject.dbrecord.id,
      current:    true
    })
    @dbrecord.reload
  end

  def element_id
    @dbrecord.element.id
  end

end

group3mat1  = SeedGroup.new("9 Mat1", current_era, subjectmaths)
group4mat3  = SeedGroup.new("10 Mat3", current_era, subjectmaths)
group5mat4  = SeedGroup.new("11 Mat4", current_era, subjectmaths)
group6mat3p = SeedGroup.new("12 Mat3P", current_era, subjectmaths)
group7mat1a = SeedGroup.new("13 Mat1A", current_era, subjectmaths)
group7fma2p = SeedGroup.new("13 FMa2P", current_era, subjectfm)
group3fre2  = SeedGroup.new("9 Fre2",  current_era, subjectfrench)


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
              "Hurley"
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
      start_year: start_year
    })
    @dbrecord.reload
  end

  def element_id
    @dbrecord.element.id
  end

end

class SeedEvent
  attr_reader :event

  def initialize(eventcategory, eventsource, body, starts_at, ends_at, more = nil)
    params = {
      body:             body,
      eventcategory_id: eventcategory.id,
      eventsource_id:   eventsource.id,
      starts_at:        starts_at,
      ends_at:          ends_at
    }
    if more
      params.merge!(more)
    end
    @event = Event.create!(params)
  end

  #
  #  Add an attendee to an event.  Must respond to element_id()
  #
  def <<(thing)
    @event.commitments.create!({ element_id: thing.element_id })
  end

end

class SeedLesson < SeedEvent

  @@lessoncategory = Eventcategory.find_by(name: "Lesson")
  unless @@lessoncategory
    raise "Can't find the lesson event category."
  end

  #
  #  All parameters should themselves be Seed<Something> objects.
  #  We get the subject for the lesson from the group.
  #
  def initialize(eventsource, staff, group, location, day, period)
    #
    #  First let's create the event itself.
    #
    starts_at = Time.zone.parse("#{day.to_s} #{period.start_time}")
    ends_at   = Time.zone.parse("#{day.to_s} #{period.end_time}")
    super(@@lessoncategory, eventsource, group.name, starts_at, ends_at)
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
    self << group.subject
    @event.reload
  end

  def covered_by(staff)
    commitment = @event.commitments.first
    @event.commitments.create!({ element_id: staff.element_id,
                                 covering_id: commitment.id })
  end

end


class SeedMeeting < SeedEvent

  @@meetingcategory = Eventcategory.find_by(name: "Meeting")
  unless @@meetingcategory
    raise "Can't find the meeting event category."
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
    super(@@meetingcategory, eventsource, title, starts_at, ends_at)
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

SeedLesson.new(thisfile, sjp, group3mat1,  l101, monday, periods[1])
SeedLesson.new(thisfile, sjp, group4mat3,  l101, monday, periods[3])
SeedLesson.new(thisfile, sjp, group7mat1a, l101, monday, periods[5])
SeedLesson.new(thisfile, sjp, group6mat3p, l101, monday, periods[6])
SeedLesson.new(thisfile, sjp, group5mat4,  l101, monday, periods[7])


SeedLesson.new(thisfile, sjp, group7mat1a, l101, tuesday, periods[2])
SeedLesson.new(thisfile, sjp, group5mat4,  l101, tuesday, periods[3])
SeedLesson.new(thisfile, sjp, group7fma2p, l101, tuesday, periods[4])
SeedLesson.new(thisfile, sjp, group3mat1,  l101, tuesday, periods[6])
SeedLesson.new(thisfile, ced, group3fre2,  l108, tuesday, periods[7]).covered_by(sjp)

SeedLesson.new(thisfile, sjp, group4mat3,  l101, wednesday, periods[1])
SeedLesson.new(thisfile, sjp, group3mat1,  l101, wednesday, periods[2])
SeedLesson.new(thisfile, sjp, group7mat1a, l101, wednesday, periods[4])
SeedLesson.new(thisfile, sjp, group6mat3p, l101, wednesday, periods[6])

SeedLesson.new(thisfile, sjp, group5mat4,  l101, thursday,  periods[2])
SeedLesson.new(thisfile, sjp, group7fma2p, l101, thursday,  periods[3])
SeedLesson.new(thisfile, sjp, group4mat3,  l101, thursday,  periods[5])
SeedLesson.new(thisfile, sjp, group7mat1a, l101, thursday,  periods[7])

SeedMeeting.new(thisfile,
                "Maths dept meeting",
                [sjp, psl, dlj],
                l102,
                thursday,
                periods[4])

SeedLesson.new(thisfile, sjp, group6mat3p, l101, friday, periods[1])
SeedLesson.new(thisfile, sjp, group5mat4,  l101, friday, periods[7])

fifthyear = Array.new
40.times do
  fifthyear << SeedPupil.new(current_era, 11)
end
