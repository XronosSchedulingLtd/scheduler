json.array!(@proto_events) do |proto_event|
  json.extract! proto_event, :id, :body, :starts_on, :ends_on, :event_category_id, :event_source_id
  json.url proto_event_url(proto_event, format: :json)
end
