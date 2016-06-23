class MIS_Staff
  SELECTOR = "HRManager CurrentStaff StaffMember"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id, :attribute, :integer],
    IsamsField["PreviousMISId",      :sb_id,    :data,      :integer],
    IsamsField["Initials",           :initials, :data,      :string],
    IsamsField["Title",              :title,    :data,      :string],
    IsamsField["Forename",           :forename, :data,      :string],
    IsamsField["Surname",            :surname,  :data,      :string],
    IsamsField["SchoolEmailAddress", :email,    :data,      :string],
    IsamsField["FullName",           :name,     :data,      :string]
  ]

  include Creator

  attr_reader :datasource_id, :current, :active

  def initialize(entry)
#    puts "In MIS_Staff initialize"
    #
    #  These two are used if a new d/b record is created.
    #
    @current = true
    @datasource_id = @@primary_datasource_id
    super
  end

  def adjust
    #
    #  We can perhaps improve the SB data a little?
    #
    if @name.blank? && !(@surname.blank? && @forename.blank?)
      @name = "#{@forename} #{@surname}"
    end
    #
    #  Whoever enters e-mail address into SB puts in random capitalisation.
    #  Take it out again.
    #
    unless @email.blank?
      @email.downcase!
    end
    #
    #  We don't really know which of the ones we get from SB are valid
    #  and which aren't.  We take an initial stab at it.
    #
    @active = !!(@email =~ /\@abingdon\.org\.uk$/)
  end

  def source_id
    @isams_id
  end

  def alternative_find_hash
    {
      :source_id => @sb_id,
      :datasource_id => @@secondary_datasource_id
    }
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data)
  end

end

