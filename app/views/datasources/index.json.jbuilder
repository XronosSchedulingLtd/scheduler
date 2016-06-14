json.array!(@datasources) do |datasource|
  json.extract! datasource, :id, :name
  json.url datasource_url(datasource, format: :json)
end
