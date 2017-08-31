json.array!(@pre_requisites) do |pre_requisite|
  json.extract! pre_requisite, :id, :label, :description, :element_id, :priority
  json.url pre_requisite_url(pre_requisite, format: :json)
end
