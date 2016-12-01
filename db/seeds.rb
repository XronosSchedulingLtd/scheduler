# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create!([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create!(name: 'Emanuel', city: cities.first)

require_relative "seedclasses"

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
#  First, some which are intrinsic to the functioning of the system.
#
weeklettercategory = Eventcategory.create!([
  ECH.new({name: "Lesson"}),
  ECH.new({name: "Week letter", schoolwide: true, privileged: true }),
  ECH.new({name: "Duty", privileged: true}),
  ECH.new({name: "Invigilation", privileged: true})
])


calendarproperty = SeedProperty.new("Calendar").
                                set_preferred_colour("#1f94bc")
gapproperty = SeedProperty.new("Gap")
suspensionproperty = SeedProperty.new("Suspension")

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

#============================================================================
#
#  Everything from here on down is demonstration data.  You probably don't
#  want to load it in a new live system.
#
#============================================================================

subjectdrama = SeedSubject.new("Drama")
SeedSubject.new("English")
subjectfrench = SeedSubject.new("French")
subjectfm     = SeedSubject.new("Further Maths")
subjectmaths  = SeedSubject.new("Mathematics")
subjectgeography = SeedSubject.new("Geography")
SeedSubject.new("German")
SeedSubject.new("History")
SeedSubject.new("Italian")
SeedSubject.new("Latin")
SeedSubject.new("Physical Education")
SeedSubject.new("Spanish")
SeedSubject.new("Sport")

sjp = SeedStaff.new("Mr", "Simon", "Philpotts", "SJP").teaches(subjectmaths).
                                                       teaches(subjectfm)
ced = SeedStaff.new("Mrs", "Claire", "Dunwoody", "CED").teaches(subjectfrench)
psl = SeedStaff.new("Ms", "Phillipa", "Long", "PSL").teaches(subjectgeography)
dlj = SeedStaff.new("Mr", "David", "Jones", "DLJ").teaches(subjectdrama)

allstaff = SeedGroup.new("All Staff", current_era).
                     members(sjp, ced, psl, dlj)

allpupils = SeedGroup.new("All Pupils", current_era)

groupgeog = SeedTeachingGroup.new("Geography pupils", current_era, subjectgeography)

mainhall = SeedLocation.new("Main Hall")
gks = SeedLocation.new("Genghis Khan Suite", "GKS")
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

calendarevents = [
  SeedEvent.new(eventcategories[1],
                thisfile,
                "3rd XV away - St Asaph's",
                Time.zone.parse("#{wednesday.to_s} 14:00"),
                Time.zone.parse("#{wednesday.to_s} 17:00"),
                {organiser_id: ced.element_id}).
            involving(calendarproperty),
  SeedEvent.new(eventcategories[1],
                thisfile,
                "2nd XV home - St Asaph's",
                Time.zone.parse("#{wednesday.to_s} 14:00"),
                Time.zone.parse("#{wednesday.to_s} 17:00"),
                {organiser_id: ced.element_id}).
            involving(calendarproperty),
  SeedEvent.new(eventcategories[2],
                thisfile,
                "Geography field trip",
                Time.zone.parse("#{thursday.to_s} 09:00"),
                Time.zone.parse("#{thursday.to_s} 17:00"),
                {organiser_id: ced.element_id}).
            involving(calendarproperty, groupgeog),
  SeedEvent.new(privilegedeventcategories[2],
                thisfile,
                "Year 9 parents' evening",
                Time.zone.parse("#{tuesday.to_s} 17:30"),
                Time.zone.parse("#{tuesday.to_s} 21:00"),
                {organiser_id: ced.element_id}).
            involving(calendarproperty),
  SeedEvent.new(eventcategories[1],
                thisfile,
                "Rowing at Eton Dorney",
                Time.zone.parse("#{saturday.to_s} 10:30"),
                Time.zone.parse("#{saturday.to_s} 15:00"),
                {organiser_id: ced.element_id}).
            involving(calendarproperty, sjp).
            add_note(
              "",
              "Please could parents not attempt to take rowers away\nbefore the end of the last event.\n\nRefreshments will be provided in the school marquee.",
              {visible_guest: true}
            ),
  SeedEvent.new(privilegedeventcategories[5],
                thisfile,
                "Founder's Assembly",
                Time.zone.parse("#{monday.to_s} 11:15"),
                Time.zone.parse("#{monday.to_s} 12:10")).
            involving(calendarproperty,
                      suspensionproperty,
                      allstaff,
                      allpupils,
                      mainhall)
]

[monday, tuesday, wednesday, thursday, friday].each do |day|
  SeedEvent.new(privilegedeventcategories[5],
                thisfile,
                "Assembly",
                Time.zone.parse("#{day.to_s} 09:00"),
                Time.zone.parse("#{day.to_s} 09:20")).
            involving(allstaff, allpupils, mainhall)
end



SeedEvent.new(privilegedeventcategories[0],
              thisfile,
              "Founder's Day",
              Time.zone.parse("#{monday.to_s}"),
              Time.zone.parse("#{tuesday.to_s}"),
              {all_day: true}).
          involving(calendarproperty)


#
#  Now some simple timetable stuff.
#

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








group3mat1  = SeedTeachingGroup.new("9 Mat1", current_era, subjectmaths)
group4mat3  = SeedTeachingGroup.new("10 Mat3", current_era, subjectmaths)
group5mat4  = SeedTeachingGroup.new("11 Mat4", current_era, subjectmaths)
group6mat3p = SeedTeachingGroup.new("12 Mat3P", current_era, subjectmaths)
group7mat1a = SeedTeachingGroup.new("13 Mat1A", current_era, subjectmaths)
group7fma2p = SeedTeachingGroup.new("13 FMa2P", current_era, subjectfm)
group3fre2  = SeedTeachingGroup.new("9 Fre2",  current_era, subjectfrench)



SeedLesson.new(thisfile, sjp, group3mat1,  l101, monday, periods[1])
SeedLesson.new(thisfile, sjp, group4mat3,  l101, monday, periods[3], {non_existent: true})
SeedLesson.new(thisfile, sjp, group7mat1a, l101, monday, periods[5])
SeedLesson.new(thisfile, sjp, group6mat3p, l101, monday, periods[6])
SeedLesson.new(thisfile, sjp, group5mat4,  l101, monday, periods[7])


SeedLesson.new(thisfile, sjp, group7mat1a, l101, tuesday, periods[2])
SeedLesson.new(thisfile, sjp, group5mat4,  l101, tuesday, periods[3])
SeedLesson.new(thisfile, sjp, group7fma2p, l101, tuesday, periods[4])
SeedLesson.new(thisfile, sjp, group3mat1,  l101, tuesday, periods[6])
SeedLesson.new(thisfile, ced, group3fre2,  l108, tuesday, periods[7]).
           covered_by(sjp).
           add_note("", "Simon - sorry you've been hit with this cover.\nThere are some worksheets on the desk at the front of the room.\nPlease collect in their books at the end of the lesson.\n\nThanks - Claire")

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

tutorgroups = [
  SeedTutorGroup.new(11, current_era, sjp, "Up"),
  SeedTutorGroup.new(11, current_era, ced, "Down"),
  SeedTutorGroup.new(11, current_era, psl, "Left"),
  SeedTutorGroup.new(11, current_era, dlj, "Right")
]

fifthyear = Array.new
4.times do
  pupil = SeedPupil.new(current_era, 11) 
  groupgeog << pupil
  group5mat4 << pupil
  fifthyear << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
20.times do
  pupil = SeedPupil.new(current_era, 11) 
  group5mat4 << pupil
  fifthyear << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
20.times do
  pupil = SeedPupil.new(current_era, 11)
  fifthyear << pupil
  groupgeog << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
20.times do
  pupil = SeedPupil.new(current_era, 11)
  fifthyear << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
