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
    if do_convert
      {
        :name => @name
      }
    else
      nil
    end
  end

  def do_convert
    self.class.do_convert
  end

  def self.construct(loader, isams_data)
    @do_convert = loader.options.do_convert
    self.slurp(isams_data.xml)
  end

  def self.do_convert
    @do_convert
  end
end


