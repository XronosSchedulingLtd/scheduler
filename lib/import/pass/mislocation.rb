class MIS_Location

  attr_reader :datasource_id, :name

  def initialize(name, description)
    #
    @datasource_id = @@primary_datasource_id
    @name        = name
    @description = description
    super
  end

  def adjust
  end

  def source_id
    @name.to_i(36)
  end

  def self.construct(loader, mis_data)
    name_hash = Hash.new
    mis_data[:timetable_records].each do |tr|
      name_hash[tr.room] ||= tr.room_description
    end
    locations = Array.new
    name_hash.each do |name, description|
      locations << MIS_Location.new(name, description)
    end
    locations
  end

end


