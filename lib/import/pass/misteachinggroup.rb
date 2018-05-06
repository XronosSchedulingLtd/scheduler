class MIS_Teachinggroup

  attr_reader :datasource_id, :current, :subject, :pupils, :pass_subject_code, :name

  def initialize(entry)
    @pupils = Array.new
    @teachers = Array.new
    @current = true
    @datasource_id = @@primary_datasource_id
    #
    @short_code        = entry.set_short_code
    @set_code          = entry.set_code
    @name              = entry.set_long_name
    @pass_subject_code = entry.subject_code.to_i(36)
    #
    #  Nowhere does the Pass data include the year group!
    #
    @year_id    = guess_year_id(entry.set_short_code)
    super
  end

  def guess_year_id(name)
    #
    #  Probably needs improving.
    #
    name[/^\d+/].to_i
  end

  def source_id
    @set_code
  end

  def source_id_str
    @set_code
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
    @subject = subject_hash[self.pass_subject_code]
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

  def self.construct(loader, mis_data)
    super
    tgs = Array.new
    tgs_hash = Hash.new
    mis_data[:set_records].each do |sr|
      unless tgs_hash[sr.set_code]
        tg = MIS_Teachinggroup.new(sr)
        tgs << tg
        tgs_hash[sr.set_code] = tg
        tg.note_subject(loader.subject_hash)
      end
      pupil = loader.pupil_hash[sr.pupil_id]
      tgs_hash[sr.set_code].add_pupil(pupil)
    end
    tgs
  end
end

