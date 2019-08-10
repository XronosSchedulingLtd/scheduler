#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLPupil
  FILE_NAME = 'TblPupilManagementPupils.csv'
  REQUIRED_COLUMNS = [
    Column['TblPupilManagementPupilsID', :id,                   :integer],
    Column['txtSchoolCode',              :school_code,          :string],
    Column['txtSchoolID',                :school_id,            :string],
    Column['txtInitials',                :initials,             :string],
    Column['txtTitle',                   :title,                :string],
    Column['txtForename',                :forename,             :string],
    Column['txtSurname',                 :surname,              :string],
    Column['txtEmailAddress',            :email_address,        :string],
    Column['intNCYear',                  :nc_year,              :integer],
    Column['txtFullName',                :full_name,            :string],
    Column['txtPreName',                 :preferred_name,       :string],
    Column['txtForm',                    :form,                 :string],
    Column['txtAcademicHouse',           :academic_house,       :string],
    Column['txtBoardingHouse',           :boarding_house,       :string]
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
    xml.Pupil(Id: self.id) do
      xml.SchoolCode         self.school_code
      xml.SchoolId           self.school_id
      xml.Initials           self.initials
      xml.Title              self.title
      xml.Forename           self.forename
      xml.Surname            self.surname
      xml.EmailAddress       self.email_address
      xml.NCYear             self.nc_year
      xml.Fullname           self.full_name
      xml.Preferredname      self.preferred_name
      xml.Form               self.form
      xml.AcademicHouse      self.academic_house
      xml.BoardingHouse      self.boarding_house
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:pupils_by_school_id] =
        records.collect {|r| [r.school_id, r]}.to_h
      @@pupils = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@pupils.each do |pupil|
      pupil.generate_entry(xml)
    end
  end

end
