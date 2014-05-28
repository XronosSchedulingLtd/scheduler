require 'csv'
require 'charlock_holmes'

#
#  A script to load in the CSV files which I've exported from SchoolBase.
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


class SB_Pupil
  FILE_NAME = "pupil.csv"
  REQUIRED_COLUMNS = [Column["PupOrigNum",       :pupil_ident,  true],
                      Column["Pu_Surname",       :surname,      false],
                      Column["Pu_Firstname",     :forename,     false],
                      Column["Pu_GivenName",     :known_as,     false],
                      Column["PupilDisplayName", :name,         false],
                      Column["PupEmail",         :email,        false],
                      Column["Pu_CandNo",        :candidate_no, false],
                      Column["YearIdent",        :year_ident,   true]]

  include Slurper

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?
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

end


class SB_Tutorgroup
  FILE_NAME = "tutorgroup.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",    :user_ident, true],
                      Column["YearIdent",    :year_ident, true],
                      Column["PupOrigNum",   :pupil_ident, true]]

  include Slurper

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?
    true
  end
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

tutorgroups, msg = SB_Tutorgroup.slurp
if msg.blank?
  puts "Read #{tutorgroups.size} tutor groups."
else
  puts "Tutorgroups: #{msg}"
end

years, msg = SB_Year.slurp
if msg.blank?
  puts "Read #{years.size} years."
else
  puts "Years: #{msg}"
end

pupils, msg = SB_Pupil.slurp
if msg.blank?
  puts "Read #{pupils.size} pupils."
else
  puts "Pupils: #{msg}"
end

if pupils && years
  year_hash = {}
  years.each do |year|
    year_hash[year.year_ident] = year
  end
  pupils_changed_count   = 0
  pupils_unchanged_count = 0
  pupils_loaded_count    = 0
  pupils.each do |pupil|
    year = year_hash[pupil.year_ident]
    if year
      dbrecord = Pupil.find_by_source_id(pupil.pupil_ident)
      if dbrecord
        changed = false
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
        if dbrecord.save
          pupils_loaded_count += 1
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
      #
      #  Staff record already exists.  Any changes?
      #
      pre_existing_count += 1
      changed = false
      if dbrecord.name != s.name
        dbrecord.name = s.name
        changed = true
      end
      if dbrecord.initials != s.initials
        dbrecord.initials = s.initials
        changed = true
      end
      if dbrecord.surname != s.surname
        dbrecord.surname = s.surname
        changed = true
      end
      if dbrecord.title != s.title
        dbrecord.title = s.title
        changed = true
      end
      if dbrecord.forename != s.forename
        dbrecord.forename = s.forename
        changed = true
      end
      if dbrecord.email != s.email
        dbrecord.email = s.email
        changed = true
      end
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
      if dbrecord.save
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
