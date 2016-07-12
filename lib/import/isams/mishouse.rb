
class MIS_House
  SELECTOR = "SchoolManager AcademicHouses House"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,       :attribute, :integer],
    IsamsField["HouseMasterId",      :housemaster_id, :attribute, :integer],
    IsamsField["Name",               :name,           :data,      :string]
  ]

  include Creator

  def initialize(entry)
    @tugs = Array.new
  end

  def note_tutorgroup(tug)
    @tugs << tug
  end

  def find_housemaster(loader)
    @housemaster = loader.staff_hash[self.housemaster_id]
    unless @housemaster
      puts "Couldn't find housemaster with id #{self.housemaster_id} for #{self.name}."
    end
  end

  def self.construct(loader, isams_data)
    houses = self.slurp(isams_data)
    @namehash = Hash.new
    houses.each do |house|
      @namehash[house.name] = house
      house.find_housemaster(loader)
    end
    houses
  end

  def self.by_name(name)
    #
    #  Find a house record, given its name.
    #
    @namehash[name]
  end

end
