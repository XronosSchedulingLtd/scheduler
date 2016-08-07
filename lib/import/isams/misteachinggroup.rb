class MIS_SetMembership
  SELECTOR = "TeachingManager SetLists SetList"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,   :attribute, :integer],
    IsamsField["SetId",     :set_id,     :attribute, :integer],
    IsamsField["PupilId",   :pupil_id,   :attribute, :integer]
  ]

  include Creator

  def initialize(entry)
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data.xml)
  end

end

class MIS_Teachinggroup
  SELECTOR = "TeachingManager Sets Set"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,   :attribute, :integer],
    IsamsField["SubjectId", :subject_id, :attribute, :integer],
    IsamsField["YearId",    :year_id,    :attribute, :integer],
    IsamsField["Name",      :name,       :data,      :string]
  ]

  include Creator

  attr_reader :datasource_id, :current, :subject

  def initialize(entry)
    @pupils = Array.new
    @current = true
    @datasource_id = @@primary_datasource_id
    #
    super
  end

  def source_id
    @isams_id
  end

  def source_id_str
    @isams_id
  end

  def adjust
  end

  def wanted
    @year_id && @year_id < 20
  end

  def note_subject(subject_hash)
    @subject = subject_hash[self.subject_id]
  end

  def start_year
    (@era.starts_on.year - @year_id) + 7
  end

  def yeargroup(loader = nil)
    @year_id - 6
  end

  def self.construct(loader, isams_data)
    super
    tgs = self.slurp(isams_data.xml)
    tgs_hash = Hash.new
    tgs.each do |tg|
      tgs_hash[tg.isams_id] = tg
      tg.note_subject(loader.subject_hash)
    end
    #
    #  Now - can I populate them?
    #
    memberships = MIS_SetMembership.construct(loader, isams_data)
    memberships.each do |membership|
      tg = tgs_hash[membership.set_id]
      pupil = loader.pupil_hash[membership.pupil_id]
      if tg && pupil
        #
        #  We are dropping a lot of teaching groups which belong
        #  to the prep school.  Don't complain about corresponding
        #  membership records.
        #
        tg.add_pupil(pupil)
      end
    end
    tgs
  end

end


