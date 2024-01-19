class ISAMS_SetMembership
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

#
#  This next is an iSAMS-specific thing.  It's a database record which lets
#  them link a tutorgroup (Form) to a lesson.  Scheduler has no need of
#  such a thing because we don't restrict how things can be linked, but
#  we need to read it in to discover which tutorgroup they want linked to
#  the lesson.
#
class MIS_TeachingForm
  SELECTOR = "TeachingManager TeachingForms TeachingForm"
  REQUIRED_FIELDS = [
    IsamsField["Id",            :isams_id,             :attribute, :integer],
    IsamsField["FormCode",      :isams_form_code,      :data,      :string],
    IsamsField["TimetableCode", :isams_timetable_code, :data,      :string],
    IsamsField["SubjectId",     :isams_subject_id,     :data,      :integer]
  ]

  include Creator

  attr_reader :subject

  def initialize(entry)
  end

  def note_subject(subject_hash)
    @subject = subject_hash[self.isams_subject_id]
  end

  def self.construct(loader, isams_data)
    tfs = self.slurp(isams_data.xml, false)
    tfs.each do |tf|
      tf.note_subject(loader.subject_hash)
    end
    tfs
  end
end


class MIS_Teachinggroup
  SELECTOR = "TeachingManager Sets Set"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,         :attribute, :integer],
    IsamsField["SubjectId", :isams_subject_id, :attribute, :integer],
    IsamsField["YearId",    :year_id,          :attribute, :integer],
    IsamsField["SetCode",   :set_code,         :data,      :string],
    IsamsField["Name",      :name,             :data,      :string]
  ]

  include Creator

  attr_reader :datasource_id, :current, :subject, :pupils

  def initialize(entry)
    @pupils = Array.new
    @teachers = Array.new
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
    @year_id && local_wanted(@year_id)
  end

  #
  #  This method is called at initialisation, whilst we're reading
  #  in our data.  At this point it is too soon to reference the actual
  #  subject database record.
  #
  def note_subject(subject_hash)
    @subject = subject_hash[self.isams_subject_id]
  end

  #
  #  This one is called later, when we are about to load into the
  #  database.  By now all the necessary subject records should
  #  have been created.
  #
  def find_subject_id
    if @subject && @subject.dbrecord
      @subject_id = @subject.dbrecord.id
    end
  end

  def start_year
    local_effective_start_year(@era, @year_id)
  end

  def yeargroup
    local_yeargroup(@year_id)
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
    memberships = ISAMS_SetMembership.construct(loader, isams_data)
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

