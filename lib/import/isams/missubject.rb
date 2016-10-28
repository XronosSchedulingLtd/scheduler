class MIS_Subject
  SELECTOR = "TeachingManager Departments Department Subjects Subject"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id,   :attribute, :integer],
    IsamsField["Name",               :isams_name, :data,      :string]
  ]

  include Creator

  attr_reader :current, :datasource_id

  def initialize(entry)
    @current = true
    @datasource_id = @@primary_datasource_id
    super()
  end

  def source_id
    @isams_id
  end

  def name
    @isams_name
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data.xml)
  end
end
