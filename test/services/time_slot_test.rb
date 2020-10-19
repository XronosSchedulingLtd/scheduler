require 'test_helper'

require 'tod'

class TimeSlotTest < ActiveSupport::TestCase

  setup do
  end

  test "must pass 1 or two parameters" do
    err = assert_raise(ArgumentError) {
      ts = TimeSlot.new
    }
    assert_match /Wrong number of arguments/, err.message
    assert_raise(ArgumentError) {
      ts = TimeSlot.new("10:00", "11:00", "12:00")
    }
    assert_match /Wrong number of arguments/, err.message
  end

  test "can have a slot lasting all day" do
    ts = TimeSlot.new("00:00", "24:00")
    assert_not_nil ts
    assert_equal 86400, ts.duration
  end

  test "one hour lasts one hour" do
    ts = TimeSlot.new("10:00", "11:00")
    assert_not_nil ts
    assert_equal 3600, ts.duration
  end

  test "parameters must be right type" do
    err = assert_raise(ArgumentError) {
      ts = TimeSlot.new(:able, :baker)
    }
    assert_match /Invalid time of day string/, err.message
  end

  test "can create a time slot from a string" do
    ts = TimeSlot.new("   10:00 - 11:15   ")
    assert_not_nil ts
  end

  test "tod rejects some strings" do
    err = assert_raise(ArgumentError) {
      TimeSlot.new("10:00 - banana")
    }
    assert_match /Invalid time of day string/, err.message
  end

  test "invalid string produces error" do
    err = assert_raise(ArgumentError) {
      ts = TimeSlot.new("Banana")
    }
    assert_match /Can't interpret .* as a time range./, err.message
  end

  test "can create a time slot from two strings" do
    ts = TimeSlot.new("10:00", "11:15")
    assert_not_nil ts
  end

  test "can create a time slot from two tods" do
    time1 = Tod::TimeOfDay.parse("10:00")
    time2 = Tod::TimeOfDay.parse("11:15")
    ts = TimeSlot.new(time1, time2)
    assert_not_nil ts
  end

  test "can create a time slot from one of each" do
    time1 = Tod::TimeOfDay.parse("10:00")
    ts = TimeSlot.new(time1, "11:15")
    assert_not_nil ts
    ts = TimeSlot.new("09:00", time1)
    assert_not_nil ts
  end
  
  test "can pass in an array of suitable things" do
    ts = TimeSlot.new(["10:00", "11:15"])
    assert_not_nil ts
    time1 = Tod::TimeOfDay.parse("10:00")
    ts = TimeSlot.new([time1, "11:15"])
    assert_not_nil ts
    time2 = Tod::TimeOfDay.parse("11:15")
    ts = TimeSlot.new(["10:00", time2])
    assert_not_nil ts
    ts = TimeSlot.new([time1, time2])
    assert_not_nil ts
  end


  test "can't be backwards" do
    err = assert_raise(ArgumentError) {
      ts = TimeSlot.new("11:15", "10:00")
    }
    assert_match /Slot duration can't be negative/, err.message
  end

  test "can sort timeslots" do
    ts1 = TimeSlot.new("08:00 - 09:00")
    ts2 = TimeSlot.new("08:30 - 10:00")
    ts3 = TimeSlot.new("08:30 - 09:00")
    ts4 = TimeSlot.new("11:20 - 12:00")

    sorted = [ts4, ts3, ts2, ts1].sort

    assert_equal [ts1, ts3, ts2, ts4], sorted
  end

  test "doesn't sort against other things" do
    ts1 = TimeSlot.new("08:00 - 09:00")
    assert_raise(Exception) {
      [ts1, :able].sort
    }
  end

  test "can compare two time slots" do
    ts1 = TimeSlot.new("08:00 - 09:00")
    ts2 = TimeSlot.new("08:30 - 10:00")
    ts3 = TimeSlot.new("09:00 - 10:00")
    assert_not ts1 < ts2
    assert ts1 < ts3
    assert_not ts2 > ts1
    assert ts3 > ts1
  end

  test "can convert to string" do
    ts1 = TimeSlot.new("8", "9")
    assert_not_nil ts1
    assert_equal "08:00 - 09:00", ts1.to_s
  end

end
