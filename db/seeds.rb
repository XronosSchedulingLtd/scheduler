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
seeder = Seeder.new(1, "xronos.uk")

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

seeder.subject(:drama,     "Drama")
seeder.subject(:english,   "English")
seeder.subject(:french,    "French")
seeder.subject(:fm,        "Further Maths")
seeder.subject(:maths,     "Mathematics")
seeder.subject(:geography, "Geography")
seeder.subject(:german,    "German")
seeder.subject(:history,   "History")
seeder.subject(:italian,   "Italian")
seeder.subject(:latin,     "Latin")
seeder.subject(:pe,        "Physical Education")
seeder.subject(:spanish,   "Spanish")
seeder.subject(:sport,     "Sport")

sjp = seeder.new_staff("Mr",  "Simon",    "Philpotts", "SJP", [:maths, :fm])
ced = seeder.new_staff("Mrs", "Claire",   "Dunwoody",  "CED", [:french])
catering = seeder.new_service("Catering")
medical = seeder.new_service("Medical")
seeder.new_user(ced).
       controls(seeder.properties[:calendarproperty]).
       controls(catering).
       controls(medical)
catering.add_prompt("Please specify in detail what you need from the catering department.\r\n\r\n* How many people?\r\n* What kind of food/drink?\r\n* Any special requirements - e.g. vegetarian?\r\n* When and where to deliver?\r\n* Do you require staff to serve food or drink?\r\n* When will you need equipment taking away?\r\n\r\nYou may also want to consider putting in a request for cleaning\r\nservices if you are having significant catering.",
                    "Edit this note to specify your catering requirements")
medical.add_prompt("",
                   "For medical centre services, please phone X273 or e-mail\r\nmedical@school to give your detailed requirements.",
                  true)

psl = seeder.new_staff("Ms",  "Phillipa", "Long",      "PSL", [:maths, 
                                                               :geography])
dlj = seeder.new_staff("Mr",  "David",    "Jones",     "DLJ", [:drama,
                                                               :maths])

prw = seeder.new_staff("Mr",  "Peter",     "Wodehouse", "PRW", [:history])
dpr = seeder.new_staff("Mrs", "Denise",    "Rowstock",  "DPR", [:german])
nlt = seeder.new_staff("Ms",  "Nina",      "Tatchell",  "NLT", [:spanish])
efl = seeder.new_staff("Mr",  "Edward",    "Lawson",    "EFL", [:sport])
srn = seeder.new_staff("Mrs", "Sarah",     "Nunn",      "SRN", [:drama])
afg = seeder.new_staff("Ms",  "Alex",      "Greene",    "AFG", [:english])

allstaff = seeder.new_group(:allstaff,
                            "All staff",
                            :current_era,
                            [:sjp, :ced, :psl, :dlj, :prw,
                             :dpr, :nlt, :efl, :srn, :afg])
year9teachers = seeder.new_group(:year9teachers,
                                 "Year 9 teachers",
                                 :current_era,
                                 [:sjp, :psl, :dlj])

allpupils = seeder.new_group(:allpupils, "All pupils", :current_era)
seeder.new_group(:year7,  "Year 7 pupils", :current_era)
seeder.new_group(:year8,  "Year 8 pupils", :current_era)
seeder.new_group(:year9,  "Year 9 pupils", :current_era)
seeder.new_group(:year10, "Year 10 pupils", :current_era)
seeder.new_group(:year11, "Year 11 pupils", :current_era)
seeder.new_group(:year12, "Year 12 pupils", :current_era)
seeder.new_group(:year13, "Year 13 pupils", :current_era)

geopupils = seeder.new_group(:geopupils, "Geography pupils", :current_era)
drapupils = seeder.new_group(:drapupils, "Drama pupils", :current_era)
engpupils = seeder.new_group(:engpupils, "English pupils", :current_era)
frepupils = seeder.new_group(:frepupils, "French pupils", :current_era)
fmapupils = seeder.new_group(:fmapupils, "Further Maths pupils", :current_era)
matpupils = seeder.new_group(:matpupils, "Maths pupils", :current_era)
gerpupils = seeder.new_group(:gerpupils, "German pupils", :current_era)
hispupils = seeder.new_group(:hispupils, "History pupils", :current_era)
itapupils = seeder.new_group(:itapupils, "Italian pupils", :current_era)
latpupils = seeder.new_group(:latpupils, "Latin pupils", :current_era)
pepupils  = seeder.new_group(:pepupils,  "PE pupils", :current_era)
spapupils = seeder.new_group(:spapupils, "Spanish pupils", :current_era)
sptpupils = seeder.new_group(:sptpupils, "Sport pupils", :current_era)

seeder.location(:mainhall, "MH", "Main Hall")
seeder.location(:gks, "GKS", "Genghis Khan Suite")
seeder.location(:l101, "L101")
seeder.location(:l102, "L102")
seeder.location(:l103, "L103")
seeder.location(:l104, "L104")
seeder.location(:l105, "L105")
seeder.location(:l106, "L106")
seeder.location(:l107, "L107")
seeder.location(:l108, "L108")
seeder.location(:l109, "L109")
seeder.location(:l110, "L110")
seeder.location(:l111, "L111")
seeder.location(:sh,   "Sports Hall")

calendarproperty = seeder.properties[:calendarproperty]
suspensionproperty = seeder.properties[:suspensionproperty]

seeder.event(:sportsfixture,
                 "3rd XV away - St Asaph's",
                 :wednesday,
                 ["14:00", "17:00"],
                 :ced).
       involving(calendarproperty)
seeder.event(:sportsfixture,
                 "2nd XV home - St Asaph's",
                 :wednesday,
                 ["14:00", "17:00"],
                 :ced).
       involving(calendarproperty)
seeder.event(:trip,
                 "Geography field trip",
                 :thursday,
                 ["09:00", "17:00"],
                 :ced,
                 {involving: [calendarproperty, geopupils]})
seeder.event(:parentsevening,
                 "Year 9 parents' evening",
                 :tuesday,
                 ["17:30", "21:00"],
                 :ced).
          involving(calendarproperty, year9teachers)
seeder.event(:sportsfixture,
                 "Rowing at Eton Dorney",
                 :saturday,
                 ["10:30", "15:00"],
                 :ced).
       involving(calendarproperty, sjp).
       add_note(
         "",
         "Please could parents not attempt to take rowers away\nbefore the end of the last event.\n\nRefreshments will be provided in the school marquee.",
         {visible_guest: true}
       )
seeder.event(:assembly,
                "Founder's Assembly",
                :monday,
                ["11:15", "12:10"]).
       involving(calendarproperty,
                 suspensionproperty,
                 allstaff,
                 allpupils,
                 seeder.locations[:mainhall])

[:monday, :tuesday, :wednesday, :thursday, :friday].each do |day|
  seeder.event(:assembly,
                   "Assembly",
                   day,
                   ["09:00", "09:20"]).
         involving(allstaff, allpupils, seeder.locations[:mainhall])
end


seeder.event(:datecrucial,
                 "Founder's Day",
                 :monday,
                 :all_day,
                 nil,
                 {involving: calendarproperty})

seeder.event(:dateother,
                 "Year 11 exams",
                 :nextmonday,
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
seeder.teaching_group(:g9mat1,   "9 Mat1",   :maths).taught_by(sjp)
seeder.teaching_group(:g10mat3,  "10 Mat3",  :maths).taught_by(sjp)
seeder.teaching_group(:g11mat3,  "11 Mat3",  :maths).taught_by(dlj)
seeder.teaching_group(:g11mat4,  "11 Mat4",  :maths).taught_by(sjp)
seeder.teaching_group(:g12mat3p, "12 Mat3P", :maths).taught_by(sjp)
seeder.teaching_group(:g13mat1a, "13 Mat1A", :maths).taught_by(sjp)
seeder.teaching_group(:g13fma2p, "13 FMa2P", :fm).taught_by(sjp)
seeder.add_to(:matpupils, seeder.groups[:g9mat1])
seeder.add_to(:matpupils, seeder.groups[:g10mat3])
seeder.add_to(:matpupils, seeder.groups[:g11mat4])
seeder.add_to(:matpupils, seeder.groups[:g12mat3p])
seeder.add_to(:matpupils, seeder.groups[:g13mat1a])
seeder.add_to(:fmapupils, seeder.groups[:g13fma2p])


seeder.lesson(:sjp, :g9mat1,   :l101, :monday, 1)
seeder.lesson(:sjp, :g10mat3,  :l101, :monday, 3, {non_existent: true})
seeder.lesson(:sjp, :g13mat1a, :l101, :monday, 5)
seeder.lesson(:sjp, :g12mat3p, :l101, :monday, 6)
seeder.lesson(:dlj, :g11mat3,  :l102, :monday, 7)
seeder.lesson(:sjp, :g11mat4,  :l101, :monday, 7)

seeder.lesson(:sjp, :g13mat1a, :l101, :tuesday, 2)
seeder.lesson(:dlj, :g11mat3,  :l102, :tuesday, 3)
seeder.lesson(:sjp, :g11mat4,  :l101, :tuesday, 3)
seeder.lesson(:sjp, :g13fma2p, :l101, :tuesday, 4)
seeder.lesson(:sjp, :g9mat1,   :l101, :tuesday, 6)

seeder.lesson(:sjp, :g10mat3,  :l101, :wednesday, 1)
seeder.lesson(:sjp, :g9mat1,   :l101, :wednesday, 2)
seeder.lesson(:sjp, :g13mat1a, :l101, :wednesday, 4)
seeder.lesson(:sjp, :g12mat3p, :l101, :wednesday, 6)

seeder.lesson(:dlj, :g11mat3,  :l102, :thursday,  2)
seeder.lesson(:sjp, :g11mat4,  :l101, :thursday,  2)
seeder.lesson(:sjp, :g13fma2p, :l101, :thursday,  3)
seeder.lesson(:sjp, :g10mat3,  :l101, :thursday,  5)
seeder.lesson(:sjp, :g13mat1a, :l101, :thursday,  7)

seeder.meeting("Maths dept meeting",
                   [:sjp, :psl, :dlj], :l102, :thursday, 4)


seeder.lesson(:sjp, :g12mat3p, :l101, :friday, 1)
seeder.lesson(:dlj, :g11mat3,  :l102, :friday, 7)
seeder.lesson(:sjp, :g11mat4,  :l101, :friday, 7)

#
#  And now a timetable for ced, who teaches French, but doesn't teach
#  year 9.
#
seeder.teaching_group(:g7fre1,   "7 Fre1",   :french).taught_by(ced)
seeder.teaching_group(:g8fre2,   "8 Fre2",   :french).taught_by(ced)
seeder.teaching_group(:g10fre3,  "10 Fre3",  :french).taught_by(ced)
seeder.teaching_group(:g11fre1a, "11 Fre1a", :french).taught_by(ced)
seeder.teaching_group(:g12fre,   "12 Fre",  :french).taught_by(ced)
seeder.teaching_group(:g13fre,   "13 Fre",  :french).taught_by(ced)
seeder.add_to(:frepupils, seeder.groups[:g7fre1])
seeder.add_to(:frepupils, seeder.groups[:g8fre2])
seeder.add_to(:frepupils, seeder.groups[:g10fre3])
seeder.add_to(:frepupils, seeder.groups[:g11fre1a])
seeder.add_to(:frepupils, seeder.groups[:g12fre])
seeder.add_to(:frepupils, seeder.groups[:g13fre])

seeder.lesson(:ced, :g7fre1,   :l108, :monday, 1)
seeder.lesson(:ced, :g10fre3,  :l108, :monday, 7)

seeder.lesson(:ced, :g13fre,   :l108, :tuesday,  2)
seeder.lesson(:ced, :g12fre,   :l108, :tuesday,  3)
seeder.lesson(:ced, :g11fre1a, :l108, :tuesday,  5)
seeder.lesson(:ced, :g8fre2,   :l108, :tuesday, 7).
       covered_by(sjp).
       add_note("", "Simon\n\nSorry you've been hit with this cover.\n\nThere are some worksheets on the desk at the front of the room.\nPlease collect in their books at the end of the lesson.\n\nThanks - Claire")

seeder.lesson(:ced, :g7fre1,   :l108, :wednesday, 1)
seeder.lesson(:ced, :g10fre3,  :l108, :wednesday, 2)
seeder.lesson(:ced, :g11fre1a, :l108, :wednesday, 3)
seeder.lesson(:ced, :g13fre,   :l108, :wednesday, 5)

seeder.lesson(:ced, :g13fre,   :l108, :thursday, 2)
seeder.lesson(:ced, :g12fre,   :l108, :thursday, 3)
seeder.lesson(:ced, :g8fre2,   :l108, :thursday, 4)
seeder.lesson(:ced, :g11fre1a, :l108, :thursday, 6)

seeder.lesson(:ced, :g7fre1,   :l108, :friday, 1)
seeder.lesson(:ced, :g8fre2,   :l108, :friday, 3)
seeder.lesson(:ced, :g10fre3,  :l108, :friday, 5)
seeder.lesson(:ced, :g13fre,   :l108, :friday, 6)
seeder.lesson(:ced, :g12fre,   :l108, :friday, 7)

seeder.meeting("French dept meeting",
                   [:ced], :l102, :tuesday, 4)

tg7 = [
  Seeder::SeedTutorGroup.new(7, seeder.eras[:current_era], prw, "Up")
]
tg8 = [
  Seeder::SeedTutorGroup.new(8, seeder.eras[:current_era], dpr, "Down")
]
tg9 = [
  Seeder::SeedTutorGroup.new(9, seeder.eras[:current_era], nlt, "Left")
]
tg10 = [
  Seeder::SeedTutorGroup.new(10, seeder.eras[:current_era], efl, "Right")
]
tg11 = [
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], sjp, "Up"),
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], ced, "Down"),
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], psl, "Left"),
  Seeder::SeedTutorGroup.new(11, seeder.eras[:current_era], dlj, "Right")
]
tg12 = [
  Seeder::SeedTutorGroup.new(12, seeder.eras[:current_era], srn, "Up")
]
tg13 = [
  Seeder::SeedTutorGroup.new(13, seeder.eras[:current_era], afg, "Down")
]

#
#  Now, I want one pupil who gets a pretty much full timetable.
#  Put him in year 11.  Create him before the others so no-one
#  else will get the same name.
#
sp = seeder.pupil(11, "James", "Greenwood")

#
#  4 pupils to go in both 11Mat4 and the Geography group
#
#  Note we are passing an array of things to populate, one of which
#  is itself an array.  Each pupil will be put into all of these
#  groups, and for the array, each pupil will be put into a randomly
#  selected one of that array).
#
#  We can pass either groups, or their keys.
#
seeder.populate([:geopupils, :g11mat4, :year11, :allpupils, tg11], 11, 4)

#
#  20 more for 11mat4
#
seeder.populate([:g11mat4, :year11, :allpupils, tg11], 11, 20)

#
#  And 20 more for the geography set
#
seeder.populate([:year11, :geopupils, :allpupils, tg11], 11, 20)

#
#  And 20 more Y11 students who aren't in either.
#
seeder.populate([:year11, :allpupils, tg11], 11, 20)

#
#  Let's populate the rest of SJP's sets.
#
seeder.populate([:year9,  :g9mat1,   :allpupils, tg9],  9, 25)
seeder.populate([:year10, :g10mat3,  :allpupils, tg10], 10, 22)
seeder.populate([:year12, :g12mat3p, :allpupils, tg12], 12, 18)
seeder.populate([:year13, :g13mat1a, :allpupils, tg13], 13, 12)
seeder.populate([:year13, :g13fma2p, :allpupils, tg13], 13,  7)

#
#  And give my special pupil some timetable, tutor group etc.
#
seeder.teaching_group(:g11dra1,   "11 Dra1",   :drama).
       taught_by(seeder.staff[:dlj])
seeder.teaching_group(:g11eng3,   "11 Eng3",   :english).
       taught_by(seeder.staff[:afg])
seeder.teaching_group(:g11geo4,   "11 Geo4",   :geography).
       taught_by(seeder.staff[:psl])
seeder.teaching_group(:g11ger2,   "11 Ger2",   :german).
       taught_by(seeder.staff[:dpr])
seeder.teaching_group(:g11his4,   "11 His4",   :history).
       taught_by(seeder.staff[:prw])
seeder.teaching_group(:g11ita1,   "11 Ita1",   :italian).
       taught_by(seeder.staff[:dpr])
seeder.teaching_group(:g11pe2,    "11 PE2",    :pe).
       taught_by(seeder.staff[:efl])
seeder.teaching_group(:g11sport,  "11 Sport",  :sport).
       taught_by(seeder.staff[:efl])
seeder.add_to(:geopupils, seeder.groups[:g11geo4])
seeder.add_to(:drapupils, seeder.groups[:g11dra1])
seeder.add_to(:engpupils, seeder.groups[:g11eng3])
seeder.add_to(:gerpupils, seeder.groups[:g11ger2])
seeder.add_to(:hispupils, seeder.groups[:g11his4])
seeder.add_to(:itapupils, seeder.groups[:g11ita1])
seeder.add_to(:pepupils,  seeder.groups[:g11pe2])
seeder.add_to(:sptpupils, seeder.groups[:g11sport])

tg11.sample << sp
seeder.add_to(:allpupils,    sp)
seeder.add_to(:year11,       sp)
seeder.add_special(:g11mat3,
                   sp,
                   seeder.era_start_date,
                   seeder.weekdates[:tuesday])
seeder.add_special(:g11mat4,
                   sp,
                   seeder.weekdates[:wednesday])
seeder.add_to(:g11fre1a,     sp)
seeder.add_to(:g11dra1,      sp)
seeder.add_to(:g11eng3,      sp)
seeder.add_to(:g11geo4,      sp)
seeder.add_to(:g11ger2,      sp)
seeder.add_to(:g11his4,      sp)
seeder.add_to(:g11ita1,      sp)
seeder.add_to(:g11pe2,       sp)
seeder.add_to(:g11sport,     sp)

seeder.lesson(:dlj, :g11dra1,   :l102, :monday, 1)
seeder.lesson(:afg, :g11eng3,   :l103, :monday, 2)
seeder.lesson(:psl, :g11geo4,   :l104, :monday, 3, {non_existent: true})
seeder.lesson(:dpr, :g11ger2,   :l105, :monday, 4)
seeder.lesson(:prw, :g11his4,   :l106, :monday, 6)

seeder.lesson(:dpr, :g11ita1,   :l102, :tuesday, 1)
seeder.lesson(:efl, :g11pe2,    :sh,   :tuesday, 2)
seeder.lesson(:prw, :g11his4,   :l106, :tuesday, 4)
seeder.lesson(:dlj, :g11dra1,   :l102, :tuesday, 6)

seeder.lesson(:dpr, :g11ger2,   :l102, :wednesday, 1)
seeder.lesson(:afg, :g11eng3,   :l103, :wednesday, 2)
seeder.lesson(:dpr, :g11ita1,   :l102, :wednesday, 4)
seeder.event(:lesson,
             "Year 11 sport",
             :wednesday,
             ["14:00", "17:00"],
             :efl).
       involving(seeder.groups[:g11sport])

seeder.lesson(:psl, :g11geo4,   :l104, :thursday, 1)
seeder.lesson(:prw, :g11his4,   :l106, :thursday, 3)
seeder.lesson(:efl, :g11pe2 ,   :sh,   :thursday, 4)
seeder.lesson(:dlj, :g11dra1,   :l102, :thursday, 5)

seeder.lesson(:dpr, :g11ger2,   :l102, :friday, 1)
seeder.lesson(:afg, :g11eng3,   :l103, :friday, 2)
seeder.lesson(:dpr, :g11ita1,   :l102, :friday, 3)
seeder.lesson(:dlj, :g11dra1,   :l102, :friday, 4)
seeder.lesson(:prw, :g11his4,   :l106, :friday, 6)

#
#  And now some suspended lessons to represent an exam day.
#
seeder.lesson(:sjp, :g9mat1,   :l101, :nextmonday, 1)
seeder.lesson(:sjp, :g10mat3,  :l101, :nextmonday, 3)
seeder.lesson(:sjp, :g13mat1a, :l101, :nextmonday, 5)
seeder.lesson(:sjp, :g12mat3p, :l101, :nextmonday, 6)
seeder.lesson(:dlj, :g11mat3,  :l102, :nextmonday, 7, {non_existent: true})
seeder.lesson(:sjp, :g11mat4,  :l101, :nextmonday, 7, {non_existent: true})

seeder.lesson(:ced, :g7fre1,   :l108, :nextmonday, 1)
seeder.lesson(:ced, :g10fre3,  :l108, :nextmonday, 7)

seeder.lesson(:dlj, :g11dra1,   :l102, :nextmonday, 1, {non_existent: true})
seeder.lesson(:afg, :g11eng3,   :l103, :nextmonday, 2, {non_existent: true})
seeder.lesson(:psl, :g11geo4,   :l104, :nextmonday, 3, {non_existent: true})
seeder.lesson(:dpr, :g11ger2,   :l105, :nextmonday, 4, {non_existent: true})
seeder.lesson(:prw, :g11his4,   :l106, :nextmonday, 6, {non_existent: true})


