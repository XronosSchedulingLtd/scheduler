json.array!(@rota_slots) do |rota_slot|
  json.extract! rota_slot, :id, :rota_template_id, :starts_at, :ends_at, :days
  json.url rota_slot_url(rota_slot, format: :json)
end
