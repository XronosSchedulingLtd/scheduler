class MIS_Customgroup < MIS_Group

  DB_CLASS = Taggroup
  DB_KEY_FIELD = [:source_id_str, :datasource_id]
  FIELDS_TO_CREATE = [:name, :era_id, :owner_id, :current]
  FIELDS_TO_UPDATE = [:name, :era_id, :owner_id, :current]

  attr_reader :pupils, :era_id, :owner_id, :current

  def add_pupil(pupil)
    @pupils << pupil
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
