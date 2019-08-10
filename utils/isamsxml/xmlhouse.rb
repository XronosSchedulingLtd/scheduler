#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLHouse
  FILE_NAME = 'TblSchoolManagementHouses.csv'
  REQUIRED_COLUMNS = [
    Column['TblSchoolManagementHousesID', :id,          :integer],
    Column['txtHouseName',                :name,        :string],
    Column['txtHouseType',                :type,        :string],
    Column['txtHouseMaster',              :housemaster, :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    staff = accumulator[:staff_by_user_code][self.housemaster]
    if staff
      @housemaster_id = staff.id
    else
      @housemaster_id = 0
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    @housemaster_id != 0
  end

  def generate_entry(xml)
    xml.House(Id: self.id, HouseMasterId: @housemaster_id) do
      xml.Name self.name
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

  def self.generate_xml(xml)
    unless @@academic_houses.empty?
      xml.AcademicHouses do
        @@academic_houses.each do |ah|
          ah.generate_entry(xml)
        end
      end
    end
    unless @@boarding_houses.empty?
      xml.BoardingHouses do
        @@boarding_houses.each do |bh|
          bh.generate_entry(xml)
        end
      end
    end
  end

end
