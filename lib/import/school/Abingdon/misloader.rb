class SB_Staff
  attr_accessor :staff_ident,
                :name,
                :initials,
                :surname,
                :title,
                :forename,
                :email,
                :active,
                :current,
                :teaches,
                :does_cover,
                :left

  def initialize(mis_staff)
    self.staff_ident = mis_staff.isams_id
    self.name        = mis_staff.name
    self.initials    = mis_staff.initials
    self.surname     = mis_staff.surname
    self.title       = mis_staff.title
    self.forename    = mis_staff.forename
    self.email       = mis_staff.email
    self.active      = true
    self.current     = true
    self.teaches     = true
    self.does_cover  = true
    self.left        = 0
  end

  def self.dump(mis_staff_list)
    staff_list = Array.new
    mis_staff_list.each do |mis_staff|
      if /@abingdon\.org\.uk$/ =~ mis_staff.email
        staff_list << SB_Staff.new(mis_staff)
      end
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "staff.yml"), "w") do |file|
      file.puts YAML::dump(staff_list)
    end
  end
end

class SB_Pupil
  attr_accessor :pupil_ident,
                :current,
                :forename,
                :known_as,
                :surname,
                :name,
                :year_ident,
                :email


  def initialize(mis_pupil, year_hash)
    self.pupil_ident = mis_pupil.sb_id
    self.current     = true
    self.forename    = mis_pupil.forename
    self.known_as    = mis_pupil.known_as
    self.surname     = mis_pupil.surname
    self.name        = mis_pupil.full_name
    self.year_ident  = year_hash[mis_pupil.nc_year].year_ident
    self.email       = mis_pupil.email
  end

  def self.dump(mis_pupils, year_hash)
    pupil_list = Array.new
    mis_pupils.each do |mis_pupil|
      pupil_list << SB_Pupil.new(mis_pupil, year_hash)
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "pupils.yml"), "w") do |file|
      file.puts YAML::dump(pupil_list)
    end
  end

end

#
#  These are emulating records which existed in SB.  Each pupil needs
#  linking to one of them.  The way to do it is via his NC year, which
#  matches year_num in this record.  We need some background information
#  in order to calculate the start_year for each record.  year_ident is
#  arbitrary (but unique).
#
class SB_Year
  attr_accessor :year_ident, :start_year, :year_num

  def initialize(our_year, current_start_year)
    self.year_ident = our_year
    self.start_year = (current_start_year - our_year) + 1
    self.year_num = our_year + 6
  end

  def self.construct
    years = Array.new
    current_start_year = Setting.current_era.starts_on.year
    1.upto(7) do |our_year|
      years << SB_Year.new(our_year, current_start_year)
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "years.yml"), "w") do |file|
      file.puts YAML::dump(years)
    end
    years
  end
end

class SB_Tutorgroupentry
  attr_accessor :pupil_ident

  def initialize(mispupil)
    self.pupil_ident = mispupil.sb_id
  end
end

class SB_Tutorgroup
  attr_accessor :name, :start_year, :house, :records, :id

  def initialize(mistug, current_start_year)
    self.id = mistug.isams_id
    self.name = mistug.name
    if mistug.year_id == 12
      self.name = self.name + "/L"
    elsif mistug.year_id == 13
      self.name = self.name + "/U"
    end
    self.start_year = (current_start_year - mistug.year_id) + 7
    self.house = mistug.house
    self.records = Array.new
    mistug.pupils.each do |mispupil|
      self.records << SB_Tutorgroupentry.new(mispupil)
    end
  end

  def self.dump(mis_tutorgroups)
    current_start_year = Setting.current_era.starts_on.year
    tghash = Hash.new
    mis_tutorgroups.each do |mistug|
      tg = SB_Tutorgroup.new(mistug, current_start_year)
      tghash[tg.id] = tg
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "tutorgroups.yml"), "w") do |file|
      file.puts YAML::dump(tghash)
    end
  end
end

PSEUDO_SUBJECTS = ["Dept. Meeting", "Tutor Period", "Invigilation"]

class SB_Subject
  attr_accessor :subject_code, :subject_name, :subject_ident, :type

  def initialize(missubject)
    self.subject_code  = "Don't care"
    self.subject_name  = missubject.name
    self.subject_ident = missubject.isams_id
    self.type          = PSEUDO_SUBJECTS.include?(missubject.name) ? :pseudo_subject : :proper_subject
  end

  def self.dump(mis_subjects)
    subjects = Array.new
    mis_subjects.each do |missubj|
      subjects << SB_Subject.new(missubj)
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "subjects.yml"), "w") do |file|
      file.puts YAML::dump(subjects)
    end
  end
end

class SB_AcademicRecord
  attr_accessor :pupil_ident

  def initialize(pupil)
    self.pupil_ident = pupil.sb_id
  end
end


class SB_Group
  attr_accessor :group_ident,
                :subject_ident,
                :name,
                :year_ident,
                :records

  def initialize(mis_group)
    self.group_ident   = mis_group.isams_id
    if mis_group.subject
      self.subject_ident = mis_group.subject.isams_id
    end
    self.name          = mis_group.name
    self.year_ident    = mis_group.year_id - 6
    self.records = Array.new
    mis_group.pupils.each do |pupil|
      self.records << SB_AcademicRecord.new(pupil)
    end
  end

  def self.dump(mis_groups, mis_timetable, loader)
    groups = Array.new
    mis_groups.each do |misgroup|
      groups << SB_Group.new(misgroup)
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "groups.yml"), "w") do |file|
      file.puts YAML::dump(groups)
    end
  end
end

class SB_Location

  attr_accessor :room_ident, :short_name, :name

  def initialize(mislocation)
    self.room_ident = mislocation.isams_id
    self.short_name = mislocation.short_name
    self.name       = mislocation.name
  end

  def self.dump(mis_locations)
    locations = Array.new
    mis_locations.each do |mislocation|
      locations << SB_Location.new(mislocation)
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "locations.yml"), "w") do |file|
      file.puts YAML::dump(locations)
    end
  end
end

class SB_PeriodTime
  attr_accessor :starts_at, :ends_at

  def initialize(mis_period)
    self.starts_at = mis_period.start_time
    self.ends_at   = mis_period.end_time
  end
end

class SB_Period
  attr_accessor :period_ident, :day_name, :week_id, :time

  def initialize(mis_period, mis_week)
    self.period_ident = mis_period.isams_id
    self.day_name     = mis_period.day.name
    self.week_id      = mis_week.isams_id
    self.time         = SB_PeriodTime.new(mis_period)
  end

  def self.dump(mis_timetable)
    periods = Array.new
    mis_timetable.weeks.each do |week|
      if week.part_time
        week.days.each do |day|
          day.periods.each do |period|
            periods << SB_Period.new(period, week)
          end
        end
      end
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "periods.yml"), "w") do |file|
      file.puts YAML::dump(periods)
    end
  end
end

class SB_Timetableentry
  attr_accessor :compound,
                :staff_idents,
                :group_idents,
                :room_idents,
                :body_text,
                :lower_school,
                :staff_ident,
                :period_ident,
                :ac_year_ident,
                :group_ident,
                :room_ident

  def initialize(mis_lesson)
    #
    #  Pretend everything is compound, and always provide the array
    #  versions.
    #
    self.compound = true
    self.staff_idents = mis_lesson.staff.collect {|s| s.isams_id}
    self.group_idents =
      mis_lesson.groups.select {|g| g.class != ISAMS_DummyGroup }.
                        collect {|g|
                          if mis_lesson.set_id == 1
                            g.isams_id
                          else
                            mis_lesson.code
                          end }
    self.room_idents  = mis_lesson.rooms.collect {|r| r.isams_id}
    self.body_text    = mis_lesson.code
    self.lower_school = false
    self.period_ident = mis_lesson.period_id
  end

  def self.dump(mis_timetable)
    #
    #  Need to be able to filter out prep school lessons.
    #
    periods_wanted = Hash.new
    mis_timetable.weeks.each do |week|
      if week.isams_id != 3
        week.days.each do |day|
          day.periods.each do |period|
            periods_wanted[period.isams_id] = true
          end
        end
      end
    end

    lessons = Array.new
    mis_timetable.schedule.entries.each do |lesson|
      if periods_wanted[lesson.period_id]
        lessons << SB_Timetableentry.new(lesson)
      end
    end
    File.open(Rails.root.join(IMPORT_DIR, "ForMarkbook", "lessons.yml"), "w") do |file|
      file.puts YAML::dump(lessons)
    end
  end

end

class MIS_Loader

  #
  #  This method is called by do_auto_groups if it exists.
  #
  def do_local_auto_groups
    #
    #  Staff by house they are tutors in.
    #
    all_tutors = []
    tutors_by_year = {}
    tges_by_year = {}
    @houses.each do |house|
      tutors = []
      pupils = []
      house_tges_by_year = {}
      house.tugs.each do |tug|
        tutors << tug.staff.dbrecord
        all_tutors << tug.staff.dbrecord
        tutors_by_year[tug.yeargroup] ||= []
        tutors_by_year[tug.yeargroup] << tug.staff.dbrecord
        #
        #  And now, each of the pupils.
        #
        tug.pupils.each do |pupil|
          tges_by_year[tug.yeargroup] ||= []
          tges_by_year[tug.yeargroup] << pupil.dbrecord
          house_tges_by_year[tug.yeargroup] ||= []
          house_tges_by_year[tug.yeargroup] << pupil.dbrecord
          pupils << pupil.dbrecord
        end
      end
      if house.name == "Lower School"
        ensure_membership("#{house.name} tutors",
                          tutors,
                          Staff)
        ensure_membership("#{house.name} pupils",
                          pupils,
                          Pupil)
      else
        ensure_membership("#{house.name} House tutors",
                          tutors,
                          Staff)
        ensure_membership("#{house.name} House pupils",
                          pupils,
                          Pupil)
        house_tges_by_year.each do |year_group, pupils|
          ensure_membership("#{house.name} House #{local_yeargroup_text(year_group)}",
                            pupils,
                            Pupil)
        end
      end
    end
    middle_school_tutors = []
    upper_school_tutors = []
    tutors_by_year.each do |year_group, tutors|
      ensure_membership("#{local_yeargroup_text(year_group)} tutors",
                        tutors,
                        Staff)
      #
      #  Lower school tutors already have their own group from the house
      #  processing.
      #
      if year_group == 3 ||
         year_group == 4 ||
         year_group == 5
        middle_school_tutors += tutors
      elsif year_group == 6 ||
            year_group == 7
        upper_school_tutors += tutors
      end
    end
    tges_by_year.each do |year_group, pupils|
      ensure_membership("#{local_yeargroup_text(year_group)}",
                        pupils,
                        Pupil)
    end
    ensure_membership("Middle school tutors", middle_school_tutors, Staff)
    ensure_membership("Upper school tutors", upper_school_tutors, Staff)
    ensure_membership("All tutors", all_tutors, Staff)
  end

  #
  #  We want some of the data for loading into Markbook.
  #  For historical reasons, all the structures are called SB_<something>
  def local_processing(options)
    SB_Staff.dump(@staff)
    years = SB_Year.construct
    year_hash = Hash.new
    years.each do |year|
      year_hash[year.year_num] = year
    end
    SB_Pupil.dump(@pupils, year_hash)
    SB_Tutorgroup.dump(@tutorgroups)
    SB_Subject.dump(@subjects)
    SB_Group.dump(@teachinggroups, @timetable, self)
    SB_Location.dump(@locations)
    SB_Period.dump(@timetable)
    SB_Timetableentry.dump(@timetable)
    @timetable.save_to_csv
  end

end
