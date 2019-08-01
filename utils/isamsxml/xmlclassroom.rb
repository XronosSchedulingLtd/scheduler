#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLClassroom
  FILE_NAME = 'TblSchoolManagementClassrooms.csv'
  REQUIRED_COLUMNS = [
    Column['TblSchoolManagementClassroomsID', :id,          :integer],
    Column['txtName',                         :name,        :string],
    Column['txtInitials',                     :initials,    :string],
    Column['intBuilding',                     :building_id, :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @building = accumulator[:buildings_by_id][self.building_id]
    @building.note_classroom(self)
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    @building != nil
  end

  def generate_entry(xml)
    xml.Classroom(Id: self.id) do
      xml.Name     self.name
      xml.Initials self.initials
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@houses = records
      @@academic_houses, @@boarding_houses =
        @@houses.partition {|h| h.type == 'Academic'}
      true
    else
      puts message
      false
    end
  end

end
