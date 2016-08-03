class MIS_Location
  SELECTOR = "EstateManager Buildings Building Classrooms Classroom"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id, :attribute, :integer],
    IsamsField["Name",      :name,     :data,      :string]
  ]

  include Creator

  attr_reader :datasource_id

  def initialize(entry)
    #
    @datasource_id = @@primary_datasource_id
    super
  end

  def adjust
  end

  def source_id
    @isams_id
  end

  def alternative_find_hash
    {
      :name => @name
    }
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data.xml)
  end

end


