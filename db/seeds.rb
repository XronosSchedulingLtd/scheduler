# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create!([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create!(name: 'Emanuel', city: cities.first)

require_relative "seedclasses"

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

#
#  It's not quite a clean slate, because the IDs carry on incrementing
#  from where they were, but at least everything is consistent.
#

#
#  The act of creating a seeder will ensure the necessary basic
#  settings records and eras exist within the system.
#
seeder = Seeder.new

#
#  First, some which are intrinsic to the functioning of the system.
#
seeder.create_essentials

#
#  And the rest fall under a heading of likely to be useful.
#
seeder.create_usefuls


#============================================================================
#
#  Everything from here on down is demonstration data.  You probably don't
#  want to load it in a new live system.
#
#============================================================================

seeder.new_subject(:drama,     "Drama")
seeder.new_subject(:english,   "English")
seeder.new_subject(:french,    "French")
seeder.new_subject(:fm,        "Further Maths")
seeder.new_subject(:maths,     "Mathematics")
seeder.new_subject(:geography, "Geography")
seeder.new_subject(:german,    "German")
seeder.new_subject(:history,   "History")
seeder.new_subject(:italian,   "Italian")
seeder.new_subject(:latin,     "Latin")
seeder.new_subject(:pe,        "Physical Education")
seeder.new_subject(:spanish,   "Spanish")
seeder.new_subject(:sport,     "Sport")

sjp = seeder.new_staff("Mr", "Simon", "Philpotts", "SJP", [:maths, :fm])
ced = seeder.new_staff("Mrs", "Claire", "Dunwoody", "CED", [:french])
psl = seeder.new_staff("Ms", "Phillipa", "Long", "PSL", [:geography])
dlj = seeder.new_staff("Mr", "David", "Jones", "DLJ", [:drama])

allstaff = seeder.new_group(:allstaff,
                            "All staff",
                            :current_era,
                            [:sjp, :ced, :psl, :dlj])
year9teachers = seeder.new_group(:year9teachers,
                                 "Year 9 teachers",
                                 :current_era,
                                 [:sjp, :ced, :psl])

allpupils = seeder.new_group(:allpupils, "All pupils", :current_era)

groupgeog = seeder.new_teaching_group(:groupgeog,
                                      "Geography pupils",
                                      :geography)

seeder.new_location(:mainhall, "Main Hall")
seeder.new_location(:gks, "Genghis Khan Suite", "GKS")
seeder.new_location(:l101, "L101")
seeder.new_location(:l102, "L102")
seeder.new_location(:l103, "L103")
seeder.new_location(:l104, "L104")
seeder.new_location(:l105, "L105")
seeder.new_location(:l106, "L106")
seeder.new_location(:l107, "L107")
seeder.new_location(:l108, "L108")
seeder.new_location(:l109, "L109")
seeder.new_location(:l110, "L110")
seeder.new_location(:l111, "L111")

calendarproperty = seeder.properties[:calendarproperty]
suspensionproperty = seeder.properties[:suspensionproperty]

calendarevents = [
  seeder.new_event(:sportsfixture,
                   "3rd XV away - St Asaph's",
                   :wednesday,
                   ["14:00", "17:00"],
                   :ced).
         involving(calendarproperty),
  seeder.new_event(:sportsfixture,
                   "2nd XV home - St Asaph's",
                   :wednesday,
                   ["14:00", "17:00"],
                   :ced).
         involving(calendarproperty),
  seeder.new_event(:trip,
                   "Geography field trip",
                   :thursday,
                   ["09:00", "17:00"],
                   :ced,
                   {involving: [calendarproperty, groupgeog]}),
  seeder.new_event(:parentsevening,
                   "Year 9 parents' evening",
                   :tuesday,
                   ["17:30", "21:00"],
                   :ced).
            involving(calendarproperty, year9teachers),
  seeder.new_event(:sportsfixture,
                   "Rowing at Eton Dorney",
                   :saturday,
                   ["10:30", "15:00"],
                   :ced).
         involving(calendarproperty, sjp).
         add_note(
           "",
           "Please could parents not attempt to take rowers away\nbefore the end of the last event.\n\nRefreshments will be provided in the school marquee.",
           {visible_guest: true}
         ),
  seeder.new_event(:assembly,
                  "Founder's Assembly",
                  :monday,
                  ["11:15", "12:10"]).
         involving(calendarproperty,
                   suspensionproperty,
                   allstaff,
                   allpupils,
                   seeder.locations[:mainhall])
]

[:monday, :tuesday, :wednesday, :thursday, :friday].each do |day|
  seeder.new_event(:assembly,
                   "Assembly",
                   day,
                   ["09:00", "09:20"]).
         involving(allstaff, allpupils, seeder.locations[:mainhall])
end


seeder.new_event(:datecrucial,
                 "Founder's Day",
                 :monday,
                 :all_day,
                 nil,
                 {involving: calendarproperty})


#
#  Now some simple timetable stuff.
#

seeder.configure_periods(
  [
    ["09:00", "09:25"],         # 0 - Assembly
    ["09:25", "10:15"],         # 1
    ["10:15", "11:05"],         # 2
    ["11:25", "12:15"],         # 3
    ["12:15", "13:05"],         # 4
    ["14:00", "14:50"],         # 5
    ["14:50", "15:40"],         # 6
    ["15:40", "16:30"]          # 7
  ]
)

#
#  Pretty much a full timetable for SJP
#
seeder.new_teaching_group(:g9mat1,   "9 Mat1",   :maths)
seeder.new_teaching_group(:g10mat3,  "10 Mat3",  :maths)
g11mat4 = seeder.new_teaching_group(:g11mat4,  "11 Mat4",  :maths)
seeder.new_teaching_group(:g12mat3p, "12 Mat3P", :maths)
seeder.new_teaching_group(:g13mat1a, "13 Mat1A", :maths)
seeder.new_teaching_group(:g13fma2p, "13 FMa2P", :fm)
seeder.new_teaching_group(:g9fre2,   "9 Fre2",   :french)


seeder.new_lesson(:sjp, :g9mat1,   :l101, :monday, 1)
seeder.new_lesson(:sjp, :g10mat3,  :l101, :monday, 3, {non_existent: true})
seeder.new_lesson(:sjp, :g13mat1a, :l101, :monday, 5)
seeder.new_lesson(:sjp, :g12mat3p, :l101, :monday, 6)
seeder.new_lesson(:sjp, :g11mat4,  :l101, :monday, 7)

seeder.new_lesson(:sjp, :g13mat1a, :l101, :tuesday, 2)
seeder.new_lesson(:sjp, :g11mat4,  :l101, :tuesday, 3)
seeder.new_lesson(:sjp, :g13fma2p, :l101, :tuesday, 4)
seeder.new_lesson(:sjp, :g9mat1,   :l101, :tuesday, 6)
seeder.new_lesson(:ced, :g9fre2,   :l108, :tuesday, 7).
       covered_by(sjp).
       add_note("", "Simon - sorry you've been hit with this cover.\nThere are some worksheets on the desk at the front of the room.\nPlease collect in their books at the end of the lesson.\n\nThanks - Claire")

seeder.new_lesson(:sjp, :g10mat3,  :l101, :wednesday, 1)
seeder.new_lesson(:sjp, :g9mat1,   :l101, :wednesday, 2)
seeder.new_lesson(:sjp, :g13mat1a, :l101, :wednesday, 4)
seeder.new_lesson(:sjp, :g12mat3p, :l101, :wednesday, 6)

seeder.new_lesson(:sjp, :g11mat4,  :l101, :thursday,  2)
seeder.new_lesson(:sjp, :g13fma2p, :l101, :thursday,  3)
seeder.new_lesson(:sjp, :g10mat3,  :l101, :thursday,  5)
seeder.new_lesson(:sjp, :g13mat1a, :l101, :thursday,  7)

seeder.new_meeting("Maths dept meeting",
                   [:sjp, :psl, :dlj], :l102, :thursday, 4)


seeder.new_lesson(:sjp, :g12mat3p, :l101, :friday, 1)
seeder.new_lesson(:sjp, :g11mat4,  :l101, :friday, 7)

tutorgroups = [
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], sjp, "Up"),
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], ced, "Down"),
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], psl, "Left"),
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], dlj, "Right")
]

fifthyear = Array.new
4.times do
  pupil = Seeder::SeedPupil.new(seeder.eras[:current_era], 11) 
  groupgeog << pupil
  g11mat4 << pupil
  fifthyear << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
20.times do
  pupil = Seeder::SeedPupil.new(seeder.eras[:current_era], 11) 
  g11mat4 << pupil
  fifthyear << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
20.times do
  pupil = Seeder::SeedPupil.new(seeder.eras[:current_era], 11)
  fifthyear << pupil
  groupgeog << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
20.times do
  pupil = Seeder::SeedPupil.new(seeder.eras[:current_era], 11)
  fifthyear << pupil
  allpupils << pupil
  tutorgroups.sample << pupil
end
