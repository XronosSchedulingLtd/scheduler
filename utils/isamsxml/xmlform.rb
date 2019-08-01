#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLForm
  FILE_NAME = 'TblSchoolManagementForms.csv'
  REQUIRED_COLUMNS = [
    Column['txtForm',       :id,              :string],
    Column['txtFormTutor',  :tutor_user_code, :string],
    Column['intNCYear',     :year_id,         :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    staff = accumulator[:staff_by_user_code][self.tutor_user_code]
    if staff
      @tutor_id = staff.id
    else
      @tutor_id = nil
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    @tutor_id != nil
  end

  def generate_entry(xml)
    xml.Form(Id: self.id, TutorId: @tutor_id, YearId: self.year_id) do
      xml.Form self.id
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@forms = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@forms.each do |form|
      form.generate_entry(xml)
    end
  end

end
