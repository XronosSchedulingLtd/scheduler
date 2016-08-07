class MIS_Customgroup < MIS_Group

  DB_CLASS = Taggroup
  add_fields(:FIELDS_TO_CREATE, [:owner_id, :make_public])
  add_fields(:FIELDS_TO_UPDATE, [:owner_id, :make_public])

  attr_reader :pupils, :owner_id, :current, :make_public

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
