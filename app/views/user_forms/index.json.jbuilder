json.array!(@user_forms) do |user_form|
  json.extract! user_form, :id, :name, :definition
  json.url user_form_url(user_form, format: :json)
end
