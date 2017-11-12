json.array!(@user_form_responses) do |user_form_response|
  json.extract! user_form_response, :id, :user_form_id, :parent_id, :parent_type, :user_id, :form_data
  json.url user_form_response_url(user_form_response, format: :json)
end
