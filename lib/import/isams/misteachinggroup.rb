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
    IsamsField["Id",        :isams_id,         :attribute, :integer],
    IsamsField["SubjectId", :isams_subject_id, :attribute, :integer],
    IsamsField["YearId",    :year_id,          :attribute, :integer],
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
    @year_id && @year_id < 20
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
    (@era.starts_on.year - @year_id) + 7
  end

  def yeargroup
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


class ISAMS_FakeTeachinggroup < MIS_Group

  DB_CLASS = Teachinggroup

  SUBJECT_CODES = {
    "Bi"  => "Biology",
    "BtB" => "Be the Best",
    "En"  => "English",
    "Fr"  => "French",
    "Gg"  => "Geography",
    "Hi"  => "History",
    "La"  => "Latin",
    "Li"  => "Reading & Research",
    "Ma"  => "Mathematics",
    "Mu"  => "Music",
    "RS"  => "Religious Studies",
    "Sc"  => "Science"
  }

  attr_reader :datasource_id,
              :current,
              :subject,
              :pupils,
              :name,
              :isams_id,
              :subject_id,
              :year_id

  def initialize(proposed_name, tutor_group, subject_hash)
    super()
    @pupils = tutor_group.pupils
    @current = true
    @datasource_id = @@primary_datasource_id
    @name = proposed_name
    @isams_id = proposed_name
    @year_id = tutor_group.year_id
    @tutor_group = tutor_group
    @subject = nil
    splut = proposed_name.split
    if splut.size == 2
      if /^[12]/ =~ splut[0]
        subject_name = SUBJECT_CODES[splut[1]]
        if subject_name
          @subject = subject_hash[subject_name]
          unless @subject
            puts "Failed to find subject #{subject_name}."
          end
        end
      end
    end
  end

  def source_id_str
    @isams_id
  end

  def start_year
    (@era.starts_on.year - @year_id) + 7
  end

  def yeargroup
    @year_id - 6
  end

  def members
    @pupils
  end
end


