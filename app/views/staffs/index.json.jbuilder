json.array!(@staffs) do |staff|
  json.extract! staff, :id, :name, :initials, :surname, :title, :forename, :email, :source_id, :active
  json.url staff_url(staff, format: :json)
end
