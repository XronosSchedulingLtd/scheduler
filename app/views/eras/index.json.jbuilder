json.array!(@eras) do |era|
  json.extract! era, :id, :name, :starts_on, :ends_on
  json.url era_url(era, format: :json)
end
