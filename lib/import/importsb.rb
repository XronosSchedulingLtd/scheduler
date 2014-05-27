require 'csv'
#
#  A script to load in the CSV files which I've exported from SchoolBase.
#

IMPORT_DIR = 'import'

Column = Struct.new(:label, :attr_name, :numeric)

#
#  A class which has the job of reading in a CSV file, making sure it
#  contains all the indicated fields, then passes the rows back one by
#  one, broken into fields.
#
class Slurper
  def self.open(filename, fields)
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
  REQUIRED_COLUMNS.each do |column|
    attr_accessor column[:attr_name]
  end
  attr_accessor :active

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

  def self.slurp
    #
    #  Slurp in a file full of staff records and return them as an array.
    #
    contents = CSV.read(Rails.root.join(IMPORT_DIR, FILE_NAME))
    puts "Read in #{contents.size} lines."
    #
    #  Do we have the necessary columns?
    #
    missing = false
    column_hash = {}
    REQUIRED_COLUMNS.each do |column|
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
          entry = SB_Staff.new
          REQUIRED_COLUMNS.each do |column|
            attr_name = column[:attr_name]
            if column.numeric
              entry.send("#{attr_name}=", row[column_hash[attr_name]].to_i)
            else
              entry.send("#{attr_name}=", row[column_hash[attr_name]])
            end
          end
          entry.adjust
          entries << entry
        end
      end
      return entries, nil
    end
  end

end

#puts Rails.root.join(IMPORT_DIR)
staff, msg = SB_Staff.slurp
if msg
  puts msg
else
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
end
