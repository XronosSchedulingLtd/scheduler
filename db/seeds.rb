# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

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
Note.destroy_all
Commitment.destroy_all
Event.destroy_all
Staff.destroy_all
Property.destroy_all
Eventsource.destroy_all
Eventcategory.destroy_all
Setting.destroy_all
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

settings = Setting.create!({
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
#  First, one which is intrinsic to the functioning of the system.
#
weeklettercategory = Eventcategory.create!(
  ECH.new({name: "Week letter", schoolwide: true, privileged: true })
)

#
#  Privileged event categories can be used by nominated users only.
#
privilegedeventcategories = Eventcategory.create([
  ECH.new({name: "Date - crucial", schoolwide: true, privileged: true }),
  ECH.new({name: "Hidden", publish: false, visible: false, privileged: true}),
  ECH.new({name: "Parents' evening", privileged: true}),
  ECH.new({name: "Reporting deadline", privileged: true}),
  ECH.new({name: "Duty", privileged: true}),
  ECH.new({name: "Tutor period", privileged: true}),
  ECH.new({name: "Assembly", privileged: true})
])


eventcategories = Eventcategory.create([
  ECH.new({name: "Lesson"}),
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

eventsources = Eventsource.create(
  [
    {
      name: "Seedfile"
    },
    {
      name: "Manual"
    }
  ]
)

thisfile = eventsources[0]

properties = Property.create(
  [
    {name: "Calendar"}
  ]
)

staff = Staff.create(
  [
    {
      name: "Simon Philpotts",
      initials: "SJP",
      surname: "Philpotts",
      title:   "Mr",
      forename: "Simon",
      email:    "simon.philpotts@xronos.org",
      active:   true,
      current:  true
    },
    {
      name: "Claire Dunwoody",
      initials: "CED",
      surname: "Dunwoody",
      title:   "Mrs",
      forename: "Claire",
      email:    "claire.dunwoody@xronos.org",
      active:   true,
      current:  true
    }
  ]
)

sjpelement = Staff.find_by(initials: "SJP").element
cedelement = Staff.find_by(initials: "CED").element

calendarelement = Element.find_by(name: "Calendar")
calendarelement.preferred_colour = "#234B58"
calendarelement.save

calendarevents = Event.create(
  [
    {
      body:             "3rd XV away - St Asaph's",
      eventcategory_id: eventcategories[1].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{wednesday.to_s} 14:00"),
      ends_at:          Time.zone.parse("#{wednesday.to_s} 17:00"),
      organiser_id:     sjpelement.id
    },
    {
      body:             "2nd XV home - St Asaph's",
      eventcategory_id: eventcategories[1].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{wednesday.to_s} 14:00"),
      ends_at:          Time.zone.parse("#{wednesday.to_s} 17:00"),
      organiser_id:     sjpelement.id
    },
    {
      body:             "Geography field trip",
      eventcategory_id: eventcategories[2].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{thursday.to_s} 09:00"),
      ends_at:          Time.zone.parse("#{thursday.to_s} 17:00"),
      organiser_id:     sjpelement.id
    },
    {
      body:             "Year 9 parents' evening",
      eventcategory_id: privilegedeventcategories[2].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{tuesday.to_s} 17:30"),
      ends_at:          Time.zone.parse("#{tuesday.to_s} 21:00"),
      organiser_id:     sjpelement.id
    },
    {
      body:             "Rowing at Eton Dorney",
      eventcategory_id: eventcategories[1].id,
      eventsource_id:   thisfile.id,
      owner_id:         nil,
      starts_at:        Time.zone.parse("#{saturday.to_s} 10:00"),
      ends_at:          Time.zone.parse("#{saturday.to_s} 15:00"),
      organiser_id:     sjpelement.id
    }
  ]
)

calendarevents.each do |ce|
  Commitment.create(
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

startofterm.commitments.create({element_id: calendarelement.id })

Commitment.create(
  {
    event_id: calendarevents[4].id,
    element_id: cedelement.id
  }
)

Note.create(
  {
    title: "",
    contents: "Please could parents not attempt to take rowers away\nbefore the end of the last event.\n\nRefreshments will be provided in the school marquee.",
    parent_id: calendarevents[4].id,
    parent_type: "Event",
    visible_guest: true,
    visible_staff: true
  }
)
