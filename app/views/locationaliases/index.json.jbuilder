json.array!(@locationaliases) do |locationalias|
  json.extract! locationalias, :id, :name, :source_id, :location_id
  json.url locationalias_url(locationalias, format: :json)
end
