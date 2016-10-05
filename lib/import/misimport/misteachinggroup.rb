class MIS_Teachinggroup < MIS_Group

  DB_CLASS = Teachinggroup

  add_fields(:FIELDS_TO_CREATE, [:subject_id])
  add_fields(:FIELDS_TO_UPDATE, [:subject_id])

  attr_reader :subject_id

  def add_pupil(pupil)
    if @pupils.include?(pupil)
      puts "Not adding #{pupil.name} to #{self.name} because he's already there." if @@loader.options.verbose
    else
      @pupils << pupil
    end
  end

  def note_teacher(staff)
    if staff.instance_of?(Array)
      staffa = staff
    else
      staffa = [staff]
    end
    staffa.each do |s|
      unless @teachers.include?(s)
        @teachers << s
      end
    end
  end

  def ensure_staff
    if @dbrecord
      staff = @teachers.collect {|t| t.dbrecord}.compact.uniq
      @dbrecord.staffs = staff
    end
  end

  def members
    @pupils
  end

  def size
    @pupils.count
  end

  #
  #  Finish off setting ourselves up.  Can only do this after discovering
  #  who our members are.
  #
  def finalize
  end

end
