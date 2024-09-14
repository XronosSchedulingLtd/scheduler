# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

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
    :house_name,
    :current,
    :datasource_id,
    :school_id
  ]

  FIELDS_TO_UPDATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :house_name,
    :current,
    :school_id
  ]

  def force_save
    if self.dbrecord
      self.dbrecord.save!
    end
  end

  #
  #  In what year would this pupil have started in the 1st year for this
  #  particular school - whatever this school calls the 1st year.
  #  Calculated from his current year group, plus the current academic
  #  year.
  #
  #  Note the inclusion of the command line option "ahead".  This is to
  #  allow pupils to be moved up by a year or two.  Useful if you're
  #  doing test loads for next year, but the pupils haven't yet been rolled
  #  over.  Thus you want pupils whom the MIS thinks are in year 5
  #  to be treated as if they were in year 6.  Note further that to
  #  move them *up* by this amount, you subtract it from their start year.
  #
  def effective_start_year(era)
    local_effective_start_year(era, self.nc_year, self.ahead)
  end

  #
  #  Everything below here should be overridden by MIS-specific code.
  #

  def self.construct(loader, mis_data)
    []
  end

end
