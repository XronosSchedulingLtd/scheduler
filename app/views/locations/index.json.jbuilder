json.array!(@locations) do |location|
  json.extract! location, :id, :short_name, :name, :active
  json.url location_url(location, format: :json)
end
