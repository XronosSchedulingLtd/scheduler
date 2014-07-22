json.array!(@groups) do |group|
  json.extract! group, :id, :name, :era_id, :current
  json.url group_url(group, format: :json)
end
