json.array!(@proto_events) do |proto_event|
  json.extract! proto_event, :id, :body, :starts_on, :ends_on, :eventcategory_id, :eventsource_id, :room, :location_id, :rota_template_name, :rota_template_id, :starts_on_text, :ends_on_text, :event_count, :num_staff
end
