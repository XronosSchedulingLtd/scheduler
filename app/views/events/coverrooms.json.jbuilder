json.array!(@coverrooms) do |crg|
  json.name crg.name
  json.rooms crg.rooms do |cr|
    json.extract! cr, :name, :element_id
  end
end
