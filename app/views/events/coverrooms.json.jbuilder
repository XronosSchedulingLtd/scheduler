json.orgroom @orgroom
json.coverrooms @coverrooms do |crg|
  json.name crg.name
  json.available crg.available
  json.rooms crg.rooms do |cr|
    json.extract! cr, :name, :element_id
    json.available crg.available
    if cr.covering
      json.selected
    end
  end
end
