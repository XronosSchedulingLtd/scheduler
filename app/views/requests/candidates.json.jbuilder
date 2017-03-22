json.array!(@candidates) do |candidate|
  json.extract! candidate, :element_id, :name, :has_suspended, :today_count, :this_week_count
end
