json.array!(@periods) do |period|
  json.extract! period, :day_no, :start_time, :end_time
end
