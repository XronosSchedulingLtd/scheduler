json.array!(@proto_events) do |proto_event|
  json.extract! proto_event, :id, :body, :starts_on, :ends_on, :eventcategory_id, :eventsource_id, :room, :rota_template_name, :starts_on_text, :ends_on_text, :event_count
end
