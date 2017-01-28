json.array!(@rota_slots) do |rota_slot|
  json.extract! rota_slot, :id, :start_second, :starts_at, :ends_at, :days
end
