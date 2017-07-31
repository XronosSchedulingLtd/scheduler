json.orgroom @orgroom
json.coverrooms @coverrooms do |crg|
  json.name crg.name
  json.rooms crg.rooms do |cr|
    json.extract! cr, :name, :element_id
    if cr.covering
      json.selected
    end
  end
end
