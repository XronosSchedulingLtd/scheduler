json.array!(@events) do |event|
  json.extract! event, :id, :body, :eventcategory_id, :eventsource_id, :owner_id, :starts_at, :ends_at, :approximate, :non_existent, :private, :reference_id, :reference_type
  json.url event_url(event, format: :json)
end
