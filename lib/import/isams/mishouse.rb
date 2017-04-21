
class MIS_House

  def initialize(entry)
    @tugs = Array.new
  end

  def note_tutorgroup(tug)
    @tugs << tug
  end

  def find_housemaster(loader)
    if self.housemaster_id
      @housemaster = loader.staff_hash[self.housemaster_id]
      unless @housemaster
        puts "Couldn't find housemaster with id #{self.housemaster_id} for #{self.name}."
      end
    else
      puts "House #{self.name} has no identified housemaster."
    end
  end

  def self.construct(loader, isams_data)
    @namehash = Hash.new
    academic_houses = ISAMS_AcademicHouse.slurp(isams_data.xml, false)
    academic_houses.each do |house|
      @namehash[house.name] = house
      house.find_housemaster(loader)
    end
    boarding_houses = ISAMS_BoardingHouse.slurp(isams_data.xml, false)
    boarding_houses.each do |house|
      @namehash[house.name] = house
      house.find_housemaster(loader)
    end
    all_houses = academic_houses + boarding_houses
    all_houses
  end

  def self.by_name(name)
    #
    #  Find a house record, given its name.
    #
    @namehash[name]
  end

end

class ISAMS_AcademicHouse < MIS_House
  SELECTOR = "SchoolManager AcademicHouses House"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,       :attribute, :integer],
    IsamsField["HouseMasterId",      :housemaster_id, :attribute, :integer],
    IsamsField["Name",               :name,           :data,      :string]
  ]

  include Creator

end

class ISAMS_BoardingHouse < MIS_House
  SELECTOR = "SchoolManager BoardingHouses House"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,       :attribute, :integer],
    IsamsField["HouseMasterId",      :housemaster_id, :attribute, :integer],
    IsamsField["Name",               :name,           :data,      :string]
  ]

  include Creator

end

