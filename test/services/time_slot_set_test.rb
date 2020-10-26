require 'test_helper'

require 'tod'

class TimeSlotSetTest < ActiveSupport::TestCase

  setup do
  end

  test "can have an empty time slot set" do
    tss = TimeSlotSet.new
    assert_not_nil tss
    assert_equal 0, tss.size
    assert tss.empty?
  end

  test "can create a set of time slots" do
    tss = TimeSlotSet.new("10:00 - 12:00", "08:00 - 09:00", "09:30 - 09:45")
    assert_not_nil tss
    assert_equal 3, tss.size
  end

  test "will accept existing slots" do
    tss = TimeSlotSet.new("10:00 - 12:00",
                          "08:00 - 09:00",
                          TimeSlot.new("09:30 - 09:45"))
    assert_not_nil tss
    assert_equal 3, tss.size
  end

  test "overlapping slots merge" do
    tss = TimeSlotSet.new("10:00 - 12:00",
                          "08:00 - 09:00",
                          "09:30 - 09:45",
                          "09:00 - 09:30",
                          "09:40 - 10:10")
    assert_not_nil tss
    assert_equal 1, tss.size
    assert_equal "08:00 - 12:00", tss[0].to_s
    tss = TimeSlotSet.new("10:00 - 12:00",
                          "08:00 - 09:00",
                          "09:00 - 09:30",
                          "09:40 - 10:10")
    assert_not_nil tss
    assert_equal 2, tss.size
    assert_equal "08:00 - 09:30", tss[0].to_s
    assert_equal "09:40 - 12:00", tss[1].to_s
  end

  test "adjacent slots merge" do
    tss = TimeSlotSet.new("10:00 - 11:00",
                          "11:00 - 12:00")
    assert_not_nil tss
    assert_equal 1, tss.size
    assert_equal "10:00 - 12:00", tss[0].to_s
  end

  test "adding a slot can reduce the set" do
    tss = TimeSlotSet.new("10:00 - 12:00",
                          "08:00 - 09:00",
                          "09:00 - 09:30",
                          "09:40 - 10:10")
    assert_not_nil tss
    assert_equal 2, tss.size
    tss << TimeSlot.new("09:30 - 09:45")
    assert_equal 1, tss.size
    assert_equal "08:00 - 12:00", tss[0].to_s
  end

  test "can remove a slot from a set" do
    tss = TimeSlotSet.new("08:00 - 12:00")
    assert_not_nil tss
    assert_equal 1, tss.size
    tss.remove(TimeSlot.new("09:15 - 10:00"))
    assert_equal 2, tss.size
    assert_equal "08:00 - 09:15", tss[0].to_s
    assert_equal "10:00 - 12:00", tss[1].to_s
  end

  test "subtracting wrong type raises error" do
    tss = TimeSlotSet.new("08:00 - 12:00")
    error = assert_raise(ArgumentError) {
      tss.remove(:apple)
    }
    assert_equal "Can't subtract object of type Symbol.", error.message
  end

  test "can remove a set from a set" do
    tss1 = TimeSlotSet.new("08:00 - 12:00")
    tss2 = TimeSlotSet.new("09:15 - 09:30", "11:15 - 11:20")
    assert_not_nil tss1
    assert_not_nil tss2
    assert_equal 1, tss1.size
    assert_equal 2, tss2.size
    tss1.remove(tss2)
    assert_equal 3, tss1.size
    assert_equal "08:00 - 09:15", tss1[0].to_s
    assert_equal "09:30 - 11:15", tss1[1].to_s
    assert_equal "11:20 - 12:00", tss1[2].to_s
  end

  test "can empty a set by subtraction" do
    tss1 = TimeSlotSet.new("08:00 - 12:00")
    tss1.remove(TimeSlot.new("09:30 - 11:00"))
    assert_equal 2, tss1.size
    assert_equal "08:00 - 09:30", tss1[0].to_s
    assert_equal "11:00 - 12:00", tss1[1].to_s
    tss1.remove(TimeSlot.new("07:30 - 10:00"))
    assert_equal 1, tss1.size
    assert_equal "11:00 - 12:00", tss1[0].to_s
    tss1.remove(TimeSlot.new("10:30 - 13:00"))
    assert_equal 0, tss1.size
    assert tss1.empty?
  end

  test "can get the intersection of two sets" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    tss2 = TimeSlotSet.new("07:30 - 10:00",
                           "11:30 - 12:30",
                           "13:30 - 15:00",
                           "16:00 - 18:00")
    tss3 = tss1 & tss2
    assert_not_nil tss3
    assert_equal 4, tss3.size
    assert_equal "08:00 - 10:00", tss3[0].to_s
    assert_equal "11:30 - 12:00", tss3[1].to_s
    assert_equal "13:30 - 15:00", tss3[2].to_s
    assert_equal "16:00 - 17:30", tss3[3].to_s
  end

  test "original is not modified by intersection" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    tss2 = TimeSlotSet.new("07:30 - 10:00",
                           "11:30 - 12:30",
                           "13:30 - 15:00",
                           "16:00 - 18:00")
    tss3 = tss1 & tss2
    assert_equal 2, tss1.size
    assert_equal "08:00 - 12:00", tss1[0].to_s
    assert_equal "13:00 - 17:30", tss1[1].to_s
  end

  test "no overlap results in an empty set" do
    tss1 = TimeSlotSet.new("08:00 - 10:00", "15:00 - 17:30")
    tss2 = TimeSlotSet.new("07:00 - 08:00", "10:15 - 11:30", "18:30 - 22:00")
    tss3 = tss1 & tss2
    assert_not_nil tss3
    assert_equal 0, tss3.size
    assert tss3.empty?
  end

  test "intersection of a set with itself results in itself" do
    tss = TimeSlotSet.new("07:30 - 10:00",
                          "11:30 - 12:30",
                          "13:30 - 15:00",
                          "16:00 - 18:00")
    result = tss & tss
    assert_not_nil result
    assert_equal tss, result
  end

  test "can intersect three sets" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    tss2 = TimeSlotSet.new("07:30 - 10:00",
                           "11:30 - 12:30",
                           "13:30 - 15:00",
                           "16:00 - 18:00")
    tss3 = TimeSlotSet.new("08:15 - 09:00",
                           "11:20 - 11:22",
                           "14:30 - 16:10",
                           "17:00 - 17:15")
    tss4 = tss1 & tss2 & tss3
    assert_not_nil tss4
    assert_equal 4, tss4.size
    assert_equal "08:15 - 09:00", tss4[0].to_s
    assert_equal "14:30 - 15:00", tss4[1].to_s
    assert_equal "16:00 - 16:10", tss4[2].to_s
    assert_equal "17:00 - 17:15", tss4[3].to_s
  end

  test "intersecting with wrong type raises error" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    error = assert_raise(ArgumentError) {
      tss2 = tss1 & :apple
    }
    assert_equal "Can't intersect with object of type Symbol.", error.message
  end

  test "can take a union of two sets" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    tss2 = TimeSlotSet.new("07:30 - 10:00",
                           "11:30 - 12:30",
                           "13:30 - 15:00",
                           "16:00 - 18:00")
    tss3 = tss1 | tss2
    assert_not_nil tss3
    assert_equal 2, tss3.size
    assert_equal "07:30 - 12:30", tss3[0].to_s
    assert_equal "13:00 - 18:00", tss3[1].to_s
  end

  test "union of a set with itself results in itself" do
    tss = TimeSlotSet.new("07:30 - 10:00",
                          "11:30 - 12:30",
                          "13:30 - 15:00",
                          "16:00 - 18:00")
    tss2 = tss | tss
    assert_not_nil tss2
    assert_equal 4, tss2.size
    assert_equal "07:30 - 10:00", tss2[0].to_s
    assert_equal "11:30 - 12:30", tss2[1].to_s
    assert_equal "13:30 - 15:00", tss2[2].to_s
    assert_equal "16:00 - 18:00", tss2[3].to_s
  end

  test "abutting slots will merge" do
    tss1 = TimeSlotSet.new("08:00 - 09:00",
                           "10:00 - 12:00")
    tss2 = TimeSlotSet.new("07:30 - 08:00",
                           "09:00 - 10:00",
                           "12:00 - 17:00")
    tss3 = tss1 | tss2
    assert_not_nil tss3
    assert_equal 1, tss3.size
    assert_equal "07:30 - 17:00", tss3[0].to_s
  end

  test "union with wrong type raises error" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    error = assert_raise(ArgumentError) {
      tss2 = tss1 | :apple
    }
    assert_equal "Can't take union with object of type Symbol.", error.message
  end

  test "subtraction does not modify original" do
    tss1 = TimeSlotSet.new("08:00 - 12:00", "13:00 - 17:30")
    tss2 = TimeSlotSet.new("07:30 - 10:00",
                           "11:30 - 12:30",
                           "13:30 - 15:00",
                           "16:00 - 18:00")
    tss3 = tss1 - tss2
    assert_not_nil tss3
    assert_equal 3, tss3.size
    assert_equal "10:00 - 11:30", tss3[0].to_s
    assert_equal "13:00 - 13:30", tss3[1].to_s
    assert_equal "15:00 - 16:00", tss3[2].to_s
    assert_equal 2, tss1.size
    assert_equal "08:00 - 12:00", tss1[0].to_s
    assert_equal "13:00 - 17:30", tss1[1].to_s
  end

  test "can identify longest slot" do
    #
    #  We expect just one back.  A sort of "sort into order of size
    #  descending, then return the first".
    #
    tss = TimeSlotSet.new("07:30 - 10:00",
                          "11:30 - 12:30",
                          "13:30 - 15:00",
                          "16:00 - 18:00")
    longest = tss.longest
    assert_not_nil longest
    assert longest.instance_of?(TimeSlot)
    assert_equal "07:30 - 10:00", longest.to_s
  end

  test "can identify slots longer than a given time" do
    tss = TimeSlotSet.new("07:30 - 10:00",
                          "11:30 - 12:30",
                          "13:30 - 15:00",
                          "16:00 - 18:00")
    tss2 = tss.at_least_mins(120)
    assert tss2.instance_of?(TimeSlotSet)
    assert_equal 2, tss2.size
    assert_equal "07:30 - 10:00", tss2[0].to_s
    assert_equal "16:00 - 18:00", tss2[1].to_s
  end

end
