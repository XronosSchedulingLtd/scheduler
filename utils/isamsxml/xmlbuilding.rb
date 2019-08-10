#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLBuilding
  FILE_NAME = 'TblSchoolManagementBuildings.csv'
  REQUIRED_COLUMNS = [
    Column['TblSchoolManagementBuildingsID', :id,   :integer],
    Column['txtName',                        :name, :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @classrooms = []
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def note_classroom(classroom)
    @classrooms << classroom
  end

  def generate_entry(xml)
    xml.Building(Id: self.id) do
      xml.Name self.name
      unless @classrooms.empty?
        xml.Classrooms do
          @classrooms.each do |classrom|
            classrom.generate_entry(xml)
          end
        end
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:buildings_by_id] =
        records.collect {|r| [r.id, r]}.to_h
      @@buildings = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@buildings.each do |building|
      building.generate_entry(xml)
    end
  end

end
