# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_Location < MIS_Record
  DB_CLASS = Locationalias
  DB_KEY_FIELD = [:source_id, :datasource_id]
  FIELDS_TO_UPDATE = [:name]
  FIELDS_TO_CREATE = [:name]

  #
  #  MIS-specific code should override the following.
  #

  def self.construct(loader, mis_data)
    []
  end

end
