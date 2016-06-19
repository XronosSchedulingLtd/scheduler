class MIS_Tutorgroup < MIS_Record

  DB_CLASS = Tutorgroup
  DB_KEY_FIELD = [:staff_id, :house, :start_year]
  FIELDS_TO_CREATE = [:name, :era_id, :current]
  FIELDS_TO_UPDATE = [:name, :era_id, :current]

  include MIS_Group

  def add_pupil(pupil)
    @pupils << pupil
  end

  def note_staff(staff)
    @staff = staff
  end

  def size
    @pupils.count
  end

  def constructed_name
    if @staff
      "#{@year_id - 6}#{@staff.initials}"
    else
      "#{isams_id}"
    end
  end

  #
  #  Finish off setting ourselves up.  Can only do this after discovering
  #  who our members are.
  #
  def finalize
    @member_ids = assemble_membership_list(@pupils)
  end

end
