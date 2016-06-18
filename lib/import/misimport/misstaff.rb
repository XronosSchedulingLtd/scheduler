class MIS_Staff < MIS_Record
  DB_CLASS = Staff
  DB_KEY_FIELD = :source_id
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
                      :current]
end
