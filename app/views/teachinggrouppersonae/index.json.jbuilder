json.array!(@teachinggroups) do |teachinggroup|
  json.extract! teachinggroup, :id, :name, :era_id, :current, :source_id
  json.url teachinggroup_url(teachinggroup, format: :json)
end
