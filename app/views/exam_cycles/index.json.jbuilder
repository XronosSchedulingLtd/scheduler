json.array!(@exam_cycles) do |exam_cycle|
  json.extract! exam_cycle, :id, :name, :default_rota_template_id
  json.url exam_cycle_url(exam_cycle, format: :json)
end
