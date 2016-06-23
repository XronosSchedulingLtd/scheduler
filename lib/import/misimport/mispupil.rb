class MIS_Pupil < MIS_Record
  #
  #  The data items referenced here must be provided by the MIS-specific
  #  code.  That is, there should be an instance variable called @name,
  #  one called @surname, etc.
  #
  DB_CLASS = Pupil
  DB_KEY_FIELD = [:source_id, :datasource_id]
  FIELDS_TO_CREATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :current,
    :datasource_id
  ]

  FIELDS_TO_UPDATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :current
  ]
  #
  #  Likewise, the platform-specific code must provide the following
  #  instance methods.
  #
  #  source_id
  #  effective_start_year
  #
  #  And most importantly, a class method called:
  #
  #  slurp
  #

  def force_save
    if self.dbrecord
      self.dbrecord.save!
    end
  end

end
