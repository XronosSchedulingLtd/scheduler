class MIS_Teachinggroup

  attr_reader :datasource_id, :current, :subject, :pupils, :name, :source_id_str

  def initialize(entry, nc_year)
    @pupils = Array.new
    @teachers = Array.new
    @current = true
    @datasource_id = @@primary_datasource_id
    #
    @short_code        = entry.set_short_code
    @set_code          = entry.set_code
    @name              = entry.set_long_name
    @pass_subject_code = entry.subject_code
    #
    #  Nowhere does the Pass data include the year group!
    #
    @year_id    = nc_year
    @source_id_str = @set_code
    super(entry)
  end

  def source_id
    @set_code
  end

  def adjust
  end

  def wanted
    @year_id && local_wanted(@year_id)
  end

  def adjust_name
    @name = "#{@name} (#{@year_id})"
    @source_id_str = "#{@source_id_str}/#{@year_id}"
  end

  #
  #  This method is called at initialisation, whilst we're reading
  #  in our data.  At this point it is too soon to reference the actual
  #  subject database record.
  #
  def note_subject(subject_hash)
    @subject = subject_hash[@pass_subject_code]
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
    #
    #  Pass is slightly unusual in that it feeds us teaching groups
    #  containing students from more than one year group.  Too much
    #  of our processing assumes that a teaching group contains
    #  pupils from just one year group.  (Groups in general have no
    #  such restriction, and we can have more than one group for
    #  a lesson.)
    #
    #  Cope with the Pass data by splitting any multi-year teaching
    #  group into several separate groups.
    #
    #  We now have a hash of hashes.  The outer hash is keyed by
    #  set_code, then within that we key by the pupil's nc_year.
    #
    #  Thus we create a teaching group for each different year
    #  group within a Pass teaching group.  We need a little
    #  extra frig to change the names of these ones.
    #
    tgs = Array.new
    tgs_hash = Hash.new
    mis_data[:set_records].each do |sr|
      group_set = (tgs_hash[sr.set_code] ||= Hash.new)
      pupil = loader.pupil_hash[sr.pupil_id]
      #
      #  We occasionally get pupils listed as being in teaching groups
      #  who have in fact left, and thus aren't in the pupil hash.
      #
      if pupil
        unless group_set[pupil.nc_year]
          tg = MIS_Teachinggroup.new(sr, pupil.nc_year)
          tg.note_subject(mis_data[:subjects_by_code])
          tgs << tg
          group_set[pupil.nc_year] = tg
        end
        group_set[pupil.nc_year].add_pupil(pupil)
      end
    end
    #
    #  Groups which have actually been split need to adjust their names.
    #
    tgs_hash.each do |key, records|
      if records.size > 1
        records.each do |year_id, record|
          record.adjust_name
        end
      end
    end
    #
    #  The timetable code needs access to this later.
    #
    mis_data[:tgs_hash] = tgs_hash
    tgs
  end
end

