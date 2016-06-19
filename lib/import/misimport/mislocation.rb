class MIS_Location < MIS_Record
  DB_CLASS = Locationalias
  DB_KEY_FIELD = [:source_id, :datasource_id]
  FIELDS_TO_UPDATE = [:name]
  FIELDS_TO_CREATE = [:name]
end
