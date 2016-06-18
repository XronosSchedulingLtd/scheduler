class MIS_Staff
  SELECTOR = "HRManager CurrentStaff StaffMember"
  REQUIRED_FIELDS = [
    IsamsField["Id",                 :isams_id, :integer],
    IsamsField["PreviousMISId",      :sb_id,    :integer],
    IsamsField["Initials",           :initials, :string],
    IsamsField["Title",              :title,    :string],
    IsamsField["Forename",           :forename, :string],
    IsamsField["Surname",            :surname,  :string],
    IsamsField["SchoolEmailAddress", :email,    :string],
    IsamsField["FullName",           :name,     :string]
  ]

  include Creator

  def initialize(entry)
    do_initialize(entry)
    #
    #  These two are used if a new d/b record is created.
    #
    @current = true
    @datasource_id = @@primary_datasource_id
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

  def source_id(secondary = false)
    if secondary
      @sb_id
    else
      @isams_id
    end
  end

end

