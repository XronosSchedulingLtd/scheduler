require 'csv'
require 'charlock_holmes'

#
#  A script to load in the CSV files which I've exported from SchoolBase.
#
#  We could really do with some sort of run-time flag to indicate whether
#  this is an original loading, in which case dates should probably be
#  taken as running from the start of the year, or a daily update, in
#  which case we should use today's date to indicate when a membership
#  started or finished.
#

IMPORT_DIR = 'import'

Column = Struct.new(:label, :attr_name, :numeric)

#
#  A module containing the common code used to read in a CSV file
#  and save it in memory records.
#
module Slurper
  def self.included(parent)
    parent::REQUIRED_COLUMNS.each do |column|
      attr_accessor column[:attr_name]
    end
    attr_accessor :db_id
    parent.send :extend, ClassMethods
  end

  module ClassMethods
    def slurp
      #
      #  Slurp in a file full of records and return them as an array.
      #
      #  Try to coerce everything to utf-8 at point of entry to avoid
      #  problems later.
      #
      raw_contents = File.read(Rails.root.join(IMPORT_DIR, self::FILE_NAME))
      detection = CharlockHolmes::EncodingDetector.detect(raw_contents)
      utf8_encoded_raw_contents =
        CharlockHolmes::Converter.convert(raw_contents,
                                          detection[:encoding],
                                          'UTF-8')
      contents = CSV.parse(utf8_encoded_raw_contents)
#      contents = CSV.read(Rails.root.join(IMPORT_DIR, self::FILE_NAME))
      puts "Read in #{contents.size} lines."
      #
      #  Do we have the necessary columns?
      #
      missing = false
      column_hash = {}
      self::REQUIRED_COLUMNS.each do |column|
        index = contents[0].find_index(column[:label])
        if index
          column_hash[column[:attr_name]] = index
        else
          missing = true
        end
      end
      if missing
        return nil, "One or more required column(s) missing."
      else
        entries = []
        contents.each_with_index do |row, i|
          if i != 0
            entry = self.new
            self::REQUIRED_COLUMNS.each do |column|
              attr_name = column[:attr_name]
              if column.numeric
                entry.send("#{attr_name}=", row[column_hash[attr_name]].to_i)
              else
                entry.send("#{attr_name}=", row[column_hash[attr_name]])
              end
            end
            entry.adjust
            if entry.wanted?
              entries << entry
            end
          end
        end
        return entries, nil
      end
    end
  end
end


class SB_AcademicRecord
  FILE_NAME = "academicrecord.csv"
  REQUIRED_COLUMNS = [Column["AcrIdent",    :acr_ident,     true],
                      Column["AcYearIdent", :ac_year_ident, true],
                      Column["PupOrigNum",  :pupil_ident,   true],
                      Column["CurrIdent",   :curriculum_ident, true],
                      Column["GroupIdent",  :group_ident,      true]]

  include Slurper

  def adjust
  end

  def wanted?
    true
  end

  def active
    true
  end

  def current
    true
  end
end


class SB_Group
  FILE_NAME = "groups.csv"
  REQUIRED_COLUMNS = [Column["GroupIdent", :group_ident, true],
                      Column["GroupName",  :name,        false]]

  include Slurper

  def adjust
  end

  def wanted?
    true
  end

  def active
    true
  end

  def current
    true
  end
end


class SB_Location
  FILE_NAME = "room.csv"
  REQUIRED_COLUMNS = [Column["RoomIdent", :room_ident, true],
                      Column["Room",      :short_name, false],
                      Column["RoomName",  :name,       false]]

  include Slurper

  def adjust
    if self.name.blank? && !self.short_name.blank?
      self.name = self.short_name
    elsif self.short_name.blank? && !self.name.blank?
      self.short_name = self.name
    end
  end

  def wanted?
    !(self.name.blank? || self.short_name.blank?)
  end

  def active
    true
  end

  def current
    true
  end
end


class SB_Pupil
  FILE_NAME = "pupil.csv"
  REQUIRED_COLUMNS = [Column["PupOrigNum",       :pupil_ident,     true],
                      Column["Pu_Surname",       :surname,         false],
                      Column["Pu_Firstname",     :forename,        false],
                      Column["Pu_GivenName",     :known_as,        false],
                      Column["PupReportName",    :name,            false],
                      Column["PupEmail",         :email,           false],
                      Column["Pu_CandNo",        :candidate_no,    false],
                      Column["YearIdent",        :year_ident,      true],
                      Column["Pu_Doe",           :date_of_entry,   false],
                      Column["PupDateofLeaving", :date_of_leaving, false],
                      Column["PType",            :ptype,           true]]

  include Slurper

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?
    #
    #  He must have a date of entry.
    #
    self.ptype == 60
#    !self.date_of_entry.blank?
  end

  def current
    true
  end

end


class SB_Staff
  FILE_NAME = "staff.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",    :sb_ident, true],
                      Column["UserName",     :name,     false],
                      Column["UserMnemonic", :initials, false],
                      Column["UserSurname",  :surname,  false],
                      Column["UserTitle",    :title,    false],
                      Column["UserForename", :forename, false],
                      Column["UserEmail",    :email,    false]]
  attr_accessor :active

  include Slurper

  def adjust
    #
    #  We can perhaps improve the SB data a little?
    #
    if self.name.blank? && !(self.surname.blank? && self.forename.blank?)
      self.name = "#{self.forename} #{self.surname}"
    end
    #
    #  We don't really know which of the ones we get from SB are valid
    #  and which aren't.  We take an initial stab at it.
    #
    self.active = !!(self.email =~ /\@abingdon\.org\.uk$/)
  end

  def wanted?
    true
  end

  def current
    self.active
  end

end


class SB_Tutorgroupentry
  FILE_NAME = "tutorgroup.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",    :user_ident,  true],
                      Column["YearIdent",    :year_ident,  true],
                      Column["PupOrigNum",   :pupil_ident, true],
                      Column["Pu_House",     :house,       false]]

  include Slurper

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?
    self.user_ident != 0 &&
    self.year_ident != 0 &&
    self.pupil_ident != 0 &&
    self.pupil_ident != -1
  end
end


class SB_Tutorgroup
  attr_accessor :name, :house, :staff_id, :era_id, :start_year, :db_id

end

class SB_Year
  FILE_NAME = "years.csv"
  REQUIRED_COLUMNS = [Column["YearIdent", :year_ident, true],
                      Column["YearDesc",  :year_num,   true],
                      Column["YearName",  :year_name,  false],
                      Column["Ptype",     :ptype,      true]]

  include Slurper

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?
    #
    #  60 seems to be the main school, whilst 40 is the prep school.
    #
    self.ptype == 60
  end

  def start_year
    #
    #  This is a bit hard-coded for now.
    #  If this is 2013/14 then someone in year 9 started in 2011.
    #
    2020 - self.year_num
  end
end

#
#  Compares selected fields in a database record and a memory record,
#  and updates any which differ.  Returns true if anything was updated
#  and false otherwise.
#
def check_and_update(dbrecord, sbrecord, fields)
  changed = false
  fields.each do |field_name|
    if dbrecord[field_name] != sbrecord.instance_variable_get("@#{field_name}")
      puts "Field #{field_name} differs for #{sbrecord.name}"
#      puts "Database: #{dbrecord[field_name]} encoding #{dbrecord[field_name].encoding}"
#      puts "Memory:   #{sbrecord.instance_variable_get("@#{field_name}")} encoding #{sbrecord.instance_variable_get("@#{field_name}").encoding}"
      dbrecord[field_name] = sbrecord.instance_variable_get("@#{field_name}")
      changed = true
    end
  end
  changed
end

tutorgroupentries, msg = SB_Tutorgroupentry.slurp
if msg.blank?
  puts "Read #{tutorgroupentries.size} tutor groups."
else
  puts "Tutorgroupentries: #{msg}"
end

years, msg = SB_Year.slurp
if msg.blank?
  puts "Read #{years.size} years."
  year_hash = {}
  years.each do |year|
    year_hash[year.year_ident] = year
  end
else
  puts "Years: #{msg}"
end

pupils, msg = SB_Pupil.slurp
if msg.blank?
  puts "Read #{pupils.size} pupils."
  pupil_hash = {}
  pupils.each do |pupil|
    pupil_hash[pupil.pupil_ident] = pupil
  end
else
  puts "Pupils: #{msg}"
end

groups, msg = SB_Group.slurp
if msg.blank?
  puts "Read #{groups.size} groups."
  group_hash = {}
  groups.each do |group|
    group_hash[group.group_ident] = group
  end
else
  puts "Groups: #{msg}"
end

ars, msg = SB_AcademicRecord.slurp
if msg.blank?
  puts "Read #{ars.size} academic records."
else
  puts "Academic records: #{msg}"
end

if pupils && years
  pupils_changed_count   = 0
  pupils_unchanged_count = 0
  pupils_loaded_count    = 0
  pupils.each do |pupil|
    year = year_hash[pupil.year_ident]
    if year
      dbrecord = Pupil.find_by_source_id(pupil.pupil_ident)
      if dbrecord
        pupil.db_id = dbrecord.id
        changed = check_and_update(dbrecord, pupil, [:name,
                                                     :forename,
                                                     :known_as,
                                                     :email,
                                                     :candidate_no])
        if dbrecord.start_year != year.start_year
          dbrecord.start_year = year.start_year
          changed = true
        end
        if changed
          if dbrecord.save
            pupils_changed_count += 1
          else
            puts "Failed to save amended pupil record for #{pupil.name}"
          end
        else
          pupils_unchanged_count += 1
        end
      else
        dbrecord = Pupil.new
        dbrecord.name         = pupil.name
        dbrecord.surname      = pupil.surname
        dbrecord.forename     = pupil.forename
        dbrecord.known_as     = pupil.known_as
        dbrecord.email        = pupil.email
        dbrecord.candidate_no = pupil.candidate_no
        dbrecord.start_year   = year.start_year
        dbrecord.source_id    = pupil.pupil_ident
        dbrecord.current      = pupil.current
        if dbrecord.save
          pupils_loaded_count += 1
          pupil.db_id = dbrecord.id
        else
          puts "Failed to save new pupil record for #{pupil.name}"
        end
      end
    end
  end
  puts "#{pupils_changed_count} pupil records amended."
  puts "#{pupils_unchanged_count} pupil records untouched."
  puts "#{pupils_loaded_count} pupil records created."
end

staff, msg = SB_Staff.slurp
if msg.blank?
  staff_hash = {}
  staff.each do |s|
    staff_hash[s.sb_ident] = s
  end
  #
  #  Should now have an array of Staff records ready to load into the
  #  database.
  #
  pre_existing_count = 0
  loaded_count = 0
  amended_count = 0
  staff.each do |s|
    dbrecord = Staff.find_by_source_id(s.sb_ident)
    if dbrecord
      s.db_id = dbrecord.id
      #
      #  Staff record already exists.  Any changes?
      #
      pre_existing_count += 1
      changed = check_and_update(dbrecord, s, [:name,
                                               :initials,
                                               :surname,
                                               :title,
                                               :forename,
                                               :email])
      #
      #  Note that, although we originally set the "active" flag, we make
      #  no attempt to amend it subsequently.
      #
      if changed
        if dbrecord.save
          amended_count += 1
        else
          puts "Failed to save amended staff record for #{s.name}"
        end
      end
    else
      #
      #  d/b record does not yet exist.
      #
      dbrecord = Staff.new
      dbrecord.name      = s.name
      dbrecord.initials  = s.initials
      dbrecord.surname   = s.surname
      dbrecord.title     = s.title
      dbrecord.forename  = s.forename
      dbrecord.email     = s.email
      dbrecord.source_id = s.sb_ident
      dbrecord.active    = s.active
      dbrecord.current   = s.current
      if dbrecord.save
        s.db_id = dbrecord.id
        loaded_count += 1
      else
        puts "Failed to save new staff record for \"#{s.name}\", sb_ident #{s.sb_ident}"
      end
    end
  end
  puts "#{pre_existing_count} staff records were already there."
  puts "#{amended_count} of these were amended."
  puts "#{loaded_count} new records created."
else
  puts "Staff: #{msg}"
end

locations, msg = SB_Location.slurp
if msg.blank?
  puts "Read #{locations.size} locations."
  location_hash = {}
  locations.each do |location|
    location_hash[location.room_ident] = location
  end
  locations_changed_count   = 0
  locations_unchanged_count = 0
  locations_loaded_count    = 0
  locations.each do |location|
    dbrecord = Location.find_by_source_id(location.room_ident)
    if dbrecord
      location.db_id = dbrecord.id
      changed = check_and_update(dbrecord, location, [:short_name, :name])
      if changed
        if dbrecord.save
          locations_changed_count += 1
        else
          puts "Failed to save amended location record for #{location.name}"
        end
      else
        locations_unchanged_count += 1
      end
    else
      dbrecord = Location.new
      dbrecord.short_name = location.short_name
      dbrecord.name       = location.name
      dbrecord.source_id  = location.room_ident
      dbrecord.active     = location.active
      dbrecord.current    = location.current
      if dbrecord.save
        location.db_id = dbrecord.id
        locations_loaded_count += 1
      else
        puts "Failed to save new location record for #{location.name}"
      end
    end
  end
  puts "#{locations_changed_count} location records amended."
  puts "#{locations_unchanged_count} location records untouched."
  puts "#{locations_loaded_count} location records created."
else
  puts "Locations: #{msg}"
end

if pupils && years && tutorgroupentries
  puts "Attempting to construct tutor groups."

  tutorgroups = []
  tg_hash = {}
  tge_accepted_count = 0
  tge_ignored_count = 0
  era = Era.first
  tutorgroupentries.each do |tge|
    staff = staff_hash[tge.user_ident]
    year  = year_hash[tge.year_ident]
    pupil = pupil_hash[tge.pupil_ident]
    if staff && year && pupil && staff.db_id && staff.active
      tge_accepted_count += 1
      unless tg_hash[tge.user_ident]
        tg = SB_Tutorgroup.new
        tg.name       = "#{year.year_num - 6}#{staff.initials}"
        tg.house      = tge.house
        tg.staff_id   = staff.db_id
        tg.era_id     = era.id
        tg.start_year = year.start_year
        tg_hash[tge.user_ident] = tg
      end
    else
      tge_ignored_count += 1
    end
  end
  puts "Accepted #{tge_accepted_count} tutor group entries."
  puts "Ignored #{tge_ignored_count} tutor group entries."
  puts "Constructed #{tg_hash.size} tutor groups."
  tg_changed_count   = 0
  tg_unchanged_count = 0
  tg_loaded_count    = 0
  tg_hash.each do |key, tg|
    dbrecord = Tutorgroup.find_by_staff_id(tg.staff_id)
    if dbrecord
      tg.db_id = dbrecord.id
      changed = check_and_update(dbrecord, tg, [:name,
                                                :house,
                                                :era_id,
                                                :start_year])
      if changed
        if dbrecord.save
          tg_changed_count += 1
        else
          puts "Failed to save amended tutorgroup record for #{tg.name}"
        end
      else
        tg_unchanged_count += 1
      end
    else
      dbrecord = Tutorgroup.new
      dbrecord.name       = tg.name
      dbrecord.house      = tg.house
      dbrecord.staff_id   = tg.staff_id
      dbrecord.era_id     = tg.era_id
      dbrecord.start_year = tg.start_year
      dbrecord.current    = true
      dbrecord.starts_on  = era.starts_on
      dbrecord.ends_on    = era.ends_on
      if dbrecord.save
        tg.db_id = dbrecord.id
        tg_loaded_count += 1
      else
        puts "Failed to save new tutorgroup record for #{tg.name}"
      end
    end
  end
  puts "#{tg_changed_count} tutorgroup records amended."
  puts "#{tg_unchanged_count} tutorgroup records untouched."
  puts "#{tg_loaded_count} tutorgroup records created."
  #
  #  And now can I put each pupil in the correct tutor group?
  #
  tgmember_removed_count   = 0
  tgmember_unchanged_count = 0
  tgmember_loaded_count    = 0
  tutorgroupentries.each do |tge|
    staff = staff_hash[tge.user_ident]
    year  = year_hash[tge.year_ident]
    pupil = pupil_hash[tge.pupil_ident]
    tg    = staff ? tg_hash[staff.sb_ident] : nil
    if staff && year && pupil && pupil.db_id && tg && staff.active
      dbpupil = Pupil.find(pupil.db_id)
      dbtg    = Tutorgroup.find(tg.db_id)
      if dbpupil && dbtg
        #
        #  Is this pupil already a member of the right tutor group?
        #
        if dbtg.member?(dbpupil, nil, false)
          tgmember_unchanged_count += 1
        else
          #
          #  No.  Is he a member of any tutor group?
          #  If so then take him out.
          #
          groups = dbpupil.element.groups
          tgroups = groups.select {|g| g.visible_group.is_a? Tutorgroup}
          tgroups.each do |tgroup|
            puts "Removing #{dbpupil.name} from #{tgroup.name}"
            tgroup.remove_member(dbpupil)
            tgmember_removed_count += 1
          end
          #
          #  And now put him in the right tutorgroup
          #
          dbtg.add_member(dbpupil)
          tgmember_loaded_count += 1
        end
      else
        puts "Can't find database record for pupil/tutorgroup. (Shouldn't happen.)"
      end
#    else
#      puts "Staff = #{staff.inspect}"
#      puts "Year = #{year.inspect}"
#      puts "Pupil = #{pupil.inspect}"
#      puts "tg = #{tg.inspect}"
#    elsif staff && year
#      puts "#{tge.inspect} nearly made it."
    end
  end
  puts "Removed #{tgmember_removed_count} pupils from tutor groups."
  puts "Left #{tgmember_unchanged_count} pupils where they were."
  puts "Added #{tgmember_loaded_count} pupils to tutor groups."
end

if ars && groups && pupils
  #
  #  So, can we load all the teaching groups as well?
  #  Drive this by the membership records - a group with no members is
  #  not terribly interesting.
  #
  groups_created_count    = 0
  pupils_added_count      = 0
  pupils_left_alone_count = 0
  dbera_hash = {}
  dbtg_hash = {}
  dbpupil_hash = {}
  today = Date.today
  ars.each do |ar|
    dbera = (dbera_hash[ar.ac_year_ident] ||= Era.find_by_source_id(ar.ac_year_ident))
    pupil  = pupil_hash[ar.pupil_ident]
    group  = group_hash[ar.group_ident]
    if dbera && pupil && group
      #
      #  One to load, or at least, check.
      #
      dbgroup = (dbtg_hash[group.group_ident] ||= Teachinggroup.find_by_source_id(group.group_ident))
      unless dbgroup
        #
        #  Doesn't seem to exist.  Can we create it?
        #
        dbgroup = Teachinggroup.new
        dbgroup.name      = group.name
        dbgroup.era       = dbera
        dbgroup.current   = true
        dbgroup.source_id = group.group_ident
        dbgroup.starts_on = era.starts_on
        if dbgroup.save
          groups_created_count += 1
          dbgroup.reload
        else
          dbgroup = nil
          puts "Failed to create teaching group #{group.name}"
        end
      end
      if dbgroup
        #
        #  Is the pupil already a member?
        #
        dbpupil = (dbpupil_hash[pupil.pupil_ident] ||= Pupil.find_by_source_id(pupil.pupil_ident))
        if dbpupil
          if dbgroup.member?(dbpupil, today, false)
            pupils_left_alone_count += 1
          else
            dbgroup.add_member(dbpupil, dbera.starts_on)
            pupils_added_count += 1
          end
        else
          puts "Couldn't find pupil #{pupil.name} in the d/b."
        end
      end
#    else
#      puts "dbera = #{dbera.inspect}"
#      puts "pupil = #{pupil.inspect}"
#      puts "group = #{group.inspect}"
    end
  end
  puts "Created #{groups_created_count} teaching groups."
  puts "Added #{pupils_added_count} to teaching groups."
  puts "Left #{pupils_left_alone_count} where they were."
end
