json.array!(@rota_templates) do |rota_template|
  json.extract! rota_template, :id, :name
  json.url rota_template_url(rota_template, format: :json)
end
