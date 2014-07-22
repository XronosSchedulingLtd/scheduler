json.array!(@tutorgroups) do |tutorgroup|
  json.extract! tutorgroup, :id, :name, :house, :staff_id, :era_id, :start_year, :current
  json.url tutorgroup_url(tutorgroup, format: :json)
end
