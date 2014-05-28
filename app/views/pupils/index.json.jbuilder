json.array!(@pupils) do |pupil|
  json.extract! pupil, :id, :name, :surname, :forename, :known_as, :email, :candidate_no, :start_year, :source_id
  json.url pupil_url(pupil, format: :json)
end
