class MIS_Tutorgroup < MIS_Group

  DB_CLASS = Tutorgroup
  DB_KEY_FIELD = [:source_id_str, :datasource_id]
  FIELDS_TO_CREATE = [:name, :era_id, :staff_id, :house, :start_year, :current]
  FIELDS_TO_UPDATE = [:name, :era_id, :staff_id, :house, :start_year, :current]

  attr_reader :staff_id

  def add_pupil(pupil)
    @pupils << pupil
  end

  def members
    @pupils
  end

  def note_staff(staff)
    @staff = staff
    @staff_id = staff.dbrecord.id
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
