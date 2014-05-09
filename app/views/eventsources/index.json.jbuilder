json.array!(@eventsources) do |eventsource|
  json.extract! eventsource, :id, :name
  json.url eventsource_url(eventsource, format: :json)
end
