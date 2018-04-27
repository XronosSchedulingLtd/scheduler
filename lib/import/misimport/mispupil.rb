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

  def force_save
    if self.dbrecord
      self.dbrecord.save!
    end
  end

  #
  #  Everything below here should be overridden by MIS-specific code.
  #

  def self.construct(loader, mis_data)
    []
  end

end
