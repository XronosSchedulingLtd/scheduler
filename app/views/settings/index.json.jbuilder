json.array!(@settings) do |setting|
  json.extract! setting, :id, :current_era_id
  json.url setting_url(setting, format: :json)
end
