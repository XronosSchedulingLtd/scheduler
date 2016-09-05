class MIS_Otherhalfgroup

  attr_reader :datasource_id, :current, :subject, :isams_id

  #
  #  iSAMS OH groups have an explicit start date.  It may change, so
  #  allow it to be updated.
  #
  add_fields(:FIELDS_TO_UPDATE, [:starts_on])

  def initialize(entry)
    @pupils = Array.new
    @name = entry.name
    @current = entry.active
    @isams_id = entry.ident
    @datasource_id = @@primary_datasource_id
    @starts_on = entry.start_date.to_date
    @ends_on = entry.end_date.to_date
    @pupil_ids = entry.pupil_ids
    super
  end

  def source_id_str
    @isams_id
  end

  def source_id
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

  def starts_on
    @starts_on
  end

  def ends_on
    @ends_on
  end

  def find_pupils(loader)
    @pupil_ids.each do |pid|
      pupil = loader.pupils_by_school_id_hash[pid]
      if pupil
        @pupils << pupil
      else
        puts "Couldn't find pupil with id #{pid}."
      end
    end
  end

  def self.construct(loader, isams_data)
    super
    oh_groups = Array.new
    isams_groups = isams_data[:groups]
    if isams_groups
      isams_groups.each do |key, record|
        oh_groups << MIS_Otherhalfgroup.new(record)
      end
    else
      puts "Can't find OH groups."
    end
    oh_groups
  end

  #
  #  We can't populate the OH groups until other data structures have
  #  been set up.
  #
  def self.populate(loader)
    loader.ohgroups.each do |ohg|
      ohg.find_pupils(loader)
    end
  end
end


