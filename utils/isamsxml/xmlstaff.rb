#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLStaff
  FILE_NAME = 'TblStaff.csv'
  REQUIRED_COLUMNS = [
    Column['TblStaffID',            :id,                   :integer],
    Column['txtPreviousMISStaffID', :previous_mis_id,      :string],
    Column['Initials',              :initials,             :string],
    Column['Title',                 :title,                :string],
    Column['Firstname',             :forename,             :string],
    Column['PreName',               :preferred_name,       :string],
    Column['Surname',               :surname,              :string],
    Column['SchoolEmailAddress',    :school_email_address, :string],
    Column['Fullname',              :full_name,            :string],
    Column['User_Code',             :user_code,            :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def generate_entry(xml)
    xml.StaffMember(Id: self.id) do
      unless self.previous_mis_id.empty?
        xml.PreviousMISId self.previous_mis_id
      end
      xml.Initials           self.initials
      xml.Title              self.title
      xml.Forename           self.forename
      xml.PreferredName      self.preferred_name
      xml.Surname            self.surname
      xml.SchoolEmailAddress self.school_email_address
      xml.FullName           self.full_name
      xml.UserCode           self.user_code
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:staff_by_user_code] =
        records.collect {|r| [r.user_code, r]}.to_h
      @@staff = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@staff.each do |staff|
      staff.generate_entry(xml)
    end
  end

end
