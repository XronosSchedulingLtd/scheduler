class MIS_Teachinggroup < MIS_Group

  DB_CLASS = Teachinggroup
  DB_KEY_FIELD = [:source_id, :datasource_id]
  FIELDS_TO_CREATE = [:name, :era_id, :current]
  FIELDS_TO_UPDATE = [:name, :era_id, :current]

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
  #  What year group do our pupils belong to?  Return 0 if we have
  #  a mixture.
  #
  def yeargroup(loader)
    ygs =
      @pupils.select {|p| p.dbrecord}.collect {|p| p.dbrecord.year_group}.uniq
    if ygs.size == 1
      ygs[0]
    else
      0
    end
  end

  #
  #  Finish off setting ourselves up.  Can only do this after discovering
  #  who our members are.
  #
  def finalize
  end

end
