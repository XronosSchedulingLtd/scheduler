# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_Staff < MIS_Record
  DB_CLASS = Staff
  DB_KEY_FIELD = [:source_id, :datasource_id]
  FIELDS_TO_CREATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :active,
                      :current,
                      :datasource_id]
  FIELDS_TO_UPDATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :active,
                      :current]

  #
  #  The MIS-specific code should override everything below here.
  #

  def self.construct(loader, mis_data)
    []
  end

end
