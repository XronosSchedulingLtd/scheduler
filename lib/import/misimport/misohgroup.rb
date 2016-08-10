class MIS_Otherhalfgroup < MIS_Group

  DB_CLASS = Otherhalfgroup

  attr_reader :name, :current

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
