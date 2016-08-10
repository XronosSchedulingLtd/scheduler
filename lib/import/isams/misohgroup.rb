class MIS_Otherhalfgroup

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
    oh_groups = Array.new
    isams_groups = isams_data[:groups]
    if isams_groups
      isams_groups.each do |key, record|
        oh_groups << MIS_Otherhalfgroup.new(record)
      end
    else
      puts "Can't find OH groups."
    end
    #
    #  Now - can I populate them?
    #
    memberships = isams_data[:grouppupillinks]
    if memberships
      memberships.each do |key, record|
      end
    else
      puts "Failed to find memberships."
    end
    oh_groups
  end

end


