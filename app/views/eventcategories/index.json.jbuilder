json.array!(@eventcategories) do |eventcategory|
  json.extract! eventcategory, :id, :name, :pecking_order, :schoolwide, :publish, :public, :for_users, :unimportant
  json.url eventcategory_url(eventcategory, format: :json)
end
