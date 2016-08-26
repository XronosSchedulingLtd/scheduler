class MIS_Teachinggroup < MIS_Group

  DB_CLASS = Teachinggroup

  def add_pupil(pupil)
    if @pupils.include?(pupil)
      puts "Not adding #{pupil.name} to #{self.name} because he's already there." unless @@loader.options.quiet
    else
      @pupils << pupil
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
