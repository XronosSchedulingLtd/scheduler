#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLCustomGroupMembership
  FILE_NAME = 'TblPupilManagementSelectionsStudents.csv'
  REQUIRED_COLUMNS = [
    Column['TblPupilManagementSelectionsStudentsID',
                                        :id,              :integer],
    Column['txtSchoolID',               :pupil_school_id, :string],
    Column['intSelectionID',            :selection_id,    :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    #
    #  We need the ID number of the associated pupil if possible.
    #
    pupil = accumulator[:pupils_by_school_id][self.pupil_school_id]
    if pupil
      @pupil_id = pupil.id
    else
      @pupil_id = 0
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    @pupil_id != 0
  end

  def generate_entry(xml)
    xml.CustomPupilGroupMembershipItem(Id: self.id, PupilID: @pupil_id) do
      xml.CustomGroupId self.selection_id
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@custom_group_memberships = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@custom_group_memberships.each do |cgm|
      cgm.generate_entry(xml)
    end
  end

end
