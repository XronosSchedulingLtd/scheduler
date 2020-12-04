require 'test_helper'

class TodShiftTest < ActiveSupport::TestCase

  setup do
  end

  test "returns correct duration when first time is lower than the second one" do
    duration_expected = 4 * 60 * 60 + 30 * 60 + 30 # 4 hours, 30 min and 30 sec later
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift = TodShift.new tod1, tod2
    duration = shift.duration
    assert_equal duration_expected, duration
  end

  test "returns correct duration when first time is greater than the second one" do
    duration_expected = 4 * 60 * 60 + 30 * 60 + 30 # 4 hours, 30 min and 30 sec later
    tod1 = Tod::TimeOfDay.new 22,30
    tod2 = Tod::TimeOfDay.new 3,00,30
    shift = TodShift.new tod1, tod2
    duration = shift.duration
    assert_equal duration_expected, duration
  end

  test "duration is zero when both times are equal" do
    tod1 = Tod::TimeOfDay.new 3,00,30
    shift = TodShift.new tod1, tod1
    duration = shift.duration
    assert_equal 0, duration
  end

  test "overlaps is true when shifts overlap" do
    shift1 = TodShift.new(Tod::TimeOfDay.new(12), Tod::TimeOfDay.new(18))
    shift2 = TodShift.new(Tod::TimeOfDay.new(13), Tod::TimeOfDay.new(15))
    assert shift1.overlaps?(shift2)

    # Additional Testing for Shifts that span from one day to another
    cases = [
      [5, 8, 7, 2],
      [7, 2, 1, 8],
      [7, 2, 5, 8],
      [4, 8, 1, 5],
      [1, 5, 4, 8],
      [7, 2, 1, 4],
      [1, 4, 7, 2],
      [1, 4, 3, 2],
      [5, 8, 7, 2],
      [7, 2, 8, 3],
      [7, 2, 6, 3],
      [7, 2, 1, 8]
    ]

    cases.each do |c|
      shift1 = TodShift.new(Tod::TimeOfDay.new(c[0]), Tod::TimeOfDay.new(c[1]))
      shift2 = TodShift.new(Tod::TimeOfDay.new(c[2]), Tod::TimeOfDay.new(c[3]))
      assert shift1.overlaps?(shift2), "Failed with args: #{c}"
    end
  end

  test "overlaps is false when shifts don't overlap" do
    shift1 = TodShift.new(Tod::TimeOfDay.new(1), Tod::TimeOfDay.new(5))
    shift2 = TodShift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(12))
    assert_not shift1.overlaps?(shift2)

    # Additional Testing for Shifts that span from one day to another
    cases = [
      [7, 8, 1, 5],
      [1, 5, 7, 8],
      [7, 2, 3, 4],
      [3, 4, 5, 2],
      [1, 5, 9, 12]
    ]

    cases.each do |c|
      shift1 = TodShift.new(Tod::TimeOfDay.new(c[0]), Tod::TimeOfDay.new(c[1]))
      shift2 = TodShift.new(Tod::TimeOfDay.new(c[2]), Tod::TimeOfDay.new(c[3]))
      assert_not shift1.overlaps?(shift2), "Failed with args: #{c}"
    end
  end

  test "overlaps is false when shifts just touch" do
    shift1 = TodShift.new(Tod::TimeOfDay.new(1), Tod::TimeOfDay.new(5), true)
    shift2 = TodShift.new(Tod::TimeOfDay.new(5), Tod::TimeOfDay.new(12), true)
    assert_not shift1.overlaps?(shift2)
  end

  test "overlaps copes correctly with zero length exclusive end shifts" do
    shift1 = TodShift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(17), true)
    shift2 = TodShift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(10), true)
    shift3 = TodShift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(9), true)
    shift4 = TodShift.new(Tod::TimeOfDay.new(17), Tod::TimeOfDay.new(17), true)
    assert shift1.overlaps?(shift2)
    assert shift2.overlaps?(shift1)

    assert_not shift1.overlaps?(shift3)
    assert_not shift3.overlaps?(shift1)

    assert_not shift1.overlaps?(shift4)
    assert_not shift4.overlaps?(shift1)

  end

  test "contains is true when one shift contains another" do
    outside = TodShift.new(Tod::TimeOfDay.new(12), Tod::TimeOfDay.new(18))
    inside = TodShift.new(Tod::TimeOfDay.new(13), Tod::TimeOfDay.new(15))
    assert outside.contains?(inside)
  end

  test "contains is false when a shift is contained by another" do
    outside = TodShift.new(Tod::TimeOfDay.new(12), Tod::TimeOfDay.new(18))
    inside = TodShift.new(Tod::TimeOfDay.new(13), Tod::TimeOfDay.new(15))
    assert_not inside.contains?(outside)
  end

  test "contains is false when shifts don't even overlap" do
    shift1 = TodShift.new(Tod::TimeOfDay.new(12), Tod::TimeOfDay.new(15))
    shift2 = TodShift.new(Tod::TimeOfDay.new(18), Tod::TimeOfDay.new(19))
    assert_not shift1.contains?(shift2)
  end

  # |------------------------|--------T1----V----T2----|------------------------|
  test "include is true when value is between ToDs and boths tods are in the same day" do
    tod1  = Tod::TimeOfDay.new 8
    tod2  = Tod::TimeOfDay.new 16
    value = Tod::TimeOfDay.new 12
    shift = TodShift.new tod1, tod2
    assert shift.include?(value)
  end

  # |------------------T1----|-------V----------T2-----|------------------------|
  test "include is true when value is on second day between ToDs and start ToD is in a different day" do
    tod1  = Tod::TimeOfDay.new 20
    tod2  = Tod::TimeOfDay.new 15
    value = Tod::TimeOfDay.new 12
    shift = TodShift.new tod1, tod2
    assert shift.include?(value)
  end

  # |------------------T1--V-|------------------T2-----|------------------------|
  test "include is true when value is on first day between ToDs and start ToD is in a different day" do
    tod1  = Tod::TimeOfDay.new 20
    tod2  = Tod::TimeOfDay.new 15
    value = Tod::TimeOfDay.new 22
    shift = TodShift.new tod1, tod2
    assert shift.include?(value)
  end

  # |------------------------|--------T1----------V----|----T2------------------|
  test "include is true when value is on first day between ToDs and end ToD is in a different day" do
    tod1  = Tod::TimeOfDay.new 16
    tod2  = Tod::TimeOfDay.new 4
    value = Tod::TimeOfDay.new 20
    shift = TodShift.new tod1, tod2
    assert shift.include?(value)
  end

  # |------------------------|--------T1---------------|--V---T2----------------|
  test "include is true when value is on second day between ToDs and end ToD is in a different day" do
    tod1  = Tod::TimeOfDay.new 16
    tod2  = Tod::TimeOfDay.new 4
    value = Tod::TimeOfDay.new 2
    shift = TodShift.new tod1, tod2
    assert shift.include?(value)
  end

  # |------------------------|--------T1-----T2----V---|------------------------|
  test "include is false when value is after second ToD" do
    tod1  = Tod::TimeOfDay.new 10
    tod2  = Tod::TimeOfDay.new 16
    value = Tod::TimeOfDay.new 20
    shift = TodShift.new tod1, tod2
    assert_not shift.include?(value)
  end

  # |------------------------|--V-----T1-----T2--------|------------------------|
  test "include is false when value is before first ToD" do
    tod1  = Tod::TimeOfDay.new 10
    tod2  = Tod::TimeOfDay.new 16
    value = Tod::TimeOfDay.new 8
    shift = TodShift.new tod1, tod2
    assert_not shift.include?(value)
  end

  # |------------------------|--------T1-----T2V-------|------------------------|
  test "include is false when value is equal to second ToD and Shift is ending exclusive" do
    tod1  = Tod::TimeOfDay.new 10
    tod2  = Tod::TimeOfDay.new 16
    value = Tod::TimeOfDay.new 16
    shift = TodShift.new tod1, tod2, true
    assert_not shift.include?(value)
  end

  # |------------------------|--------T1-----T2V-------|------------------------|

  test "equalsequals is true when the beginning time, end time, and exclude end are the same" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new tod1, tod2
    assert shift1 == shift2
  end

  test "equalsequals is false when the beginning time is different" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new tod1, Tod::TimeOfDay.new(14,00)
    assert !(shift1 == shift2)
  end

  test "equalsequals is false when the ending time is different" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new Tod::TimeOfDay.new(9,30), tod2
    assert !(shift1 == shift2)
  end

  test "eql is true when the beginning time, end time, and exclude end are the same" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new tod1, tod2
    assert shift1.eql?(shift2)
  end

  test "eql is false when the beginning time is different" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new tod1, Tod::TimeOfDay.new(14,00)
    assert !shift1.eql?(shift2)
  end

  test "eql is false when the ending time is different" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new Tod::TimeOfDay.new(9,30), tod2
    assert !shift1.eql?(shift2)
  end

  test "hash is the same when the beginning time, end time, and exclude end are the same" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new tod1, tod2
    assert_equal shift1.hash, shift2.hash
  end

  test "hash is usually different when the beginning time is different" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new tod1, Tod::TimeOfDay.new(14,00)
    assert shift1.hash != shift2.hash
  end

  test "hash is usually different when the ending time is different" do
    tod1 = Tod::TimeOfDay.new 8,30
    tod2 = Tod::TimeOfDay.new 13,00,30
    shift1 = TodShift.new tod1, tod2
    shift2 = TodShift.new Tod::TimeOfDay.new(9,30), tod2
    assert shift1.hash != shift2.hash
  end

  test "slide handles positive numbers" do
    slide = 30 * 60 # 30 minutes in seconds

    beginning_expected = Tod::TimeOfDay.new 10, 30
    ending_expected = Tod::TimeOfDay.new 16, 30

    beginning  = Tod::TimeOfDay.new 10
    ending  = Tod::TimeOfDay.new 16
    shift = TodShift.new(beginning, ending).slide(slide)

    assert_equal beginning_expected, shift.beginning
    assert_equal ending_expected, shift.ending
    assert shift.exclude_end?
  end

  test "slide handles negative numbers" do
    slide = -30 * 60 # -30 minutes in seconds

    beginning_expected = Tod::TimeOfDay.new 9, 30
    ending_expected = Tod::TimeOfDay.new 15, 30

    beginning  = Tod::TimeOfDay.new 10
    ending  = Tod::TimeOfDay.new 16
    shift = TodShift.new(beginning, ending).slide(slide)

    assert_equal beginning_expected, shift.beginning
    assert_equal ending_expected, shift.ending
    assert shift.exclude_end?
  end

  test "slide handles ActiveSupport::Duration" do
    slide = 30.minutes

    beginning_expected = Tod::TimeOfDay.new 10, 30
    ending_expected = Tod::TimeOfDay.new 16, 30

    beginning  = Tod::TimeOfDay.new 10
    ending  = Tod::TimeOfDay.new 16
    shift = TodShift.new(beginning, ending).slide(slide)

    assert_equal beginning_expected, shift.beginning
    assert_equal ending_expected, shift.ending
    assert shift.exclude_end?
  end

end
