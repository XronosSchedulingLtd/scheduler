require 'test_helper'

class DateRangeTest < ActiveSupport::TestCase

  setup do
  end

  test "can create from strings" do
    dr1 = DateRange.new("2021-11-30", "2021-12-5")
    assert_equal 5, dr1.duration
  end

  test "formats sensibly" do
    dr1 = DateRange.new("2021-11-30", "2021-12-5")
    #
    #  Note that this is intended to be human-friendly and so shows
    #  the inclusive end date.  All internal processing is done with
    #  an external date.
    #
    assert_equal "30/11/2021 - 04/12/2021", dr1.to_s
  end

  test "can create from dates" do
    dr1 = DateRange.new(Date.parse("2021-11-30"), Date.parse("2021-12-5"))
    assert_equal 5, dr1.duration
  end

  test "can create from times" do
    dr1 = DateRange.new(Time.parse("2021-11-30"), Time.parse("2021-12-5"))
    assert_equal 5, dr1.duration
  end

  test "can create from times with zone" do
    dr1 = DateRange.new(
      Time.zone.parse("2021-11-30"), Time.zone.parse("2021-12-5"))
    assert_equal 5, dr1.duration
  end

  test "can create by passing a duration" do
    dr1 = DateRange.new("2021-11-01", 5)
    dr2 = DateRange.new("2021-11-01", 5.days)
    assert_equal 5, dr1.duration
    assert_equal 5, dr2.duration
  end

  test "duration is zero when both dates are equal" do
    dr1 = DateRange.new("2021-11-30", "2021-11-30")
    assert_equal 0, dr1.duration
  end

  test "overlaps is true when dates overlap" do
    dr1 = DateRange.new("2021-11-05", "2021-11-20")
    dr2 = DateRange.new("2021-11-19", "2021-11-25")
    assert dr1.overlaps?(dr2)
  end

  test "overlaps is false when dates don't overlap" do
    dr1 = DateRange.new("2021-11-05", "2021-11-20")
    dr2 = DateRange.new("2021-11-21", "2021-11-25")
    assert_not dr1.overlaps?(dr2)
  end

  test "overlaps is false when dates just touch" do
    dr1 = DateRange.new("2021-11-05", "2021-11-20")
    dr2 = DateRange.new("2021-11-20", "2021-11-25")
    assert_not dr1.overlaps?(dr2)
  end

  test "overlaps copes correctly with zero length ranges" do
    dr1 = DateRange.new("2021-11-09", "2021-11-17")
    dr2 = DateRange.new("2021-11-10", "2021-11-10")
    dr3 = DateRange.new("2021-11-09", "2021-11-09")
    dr4 = DateRange.new("2021-11-17", "2021-11-17")
    assert dr1.overlaps?(dr2)
    assert dr2.overlaps?(dr1)

    assert_not dr1.overlaps?(dr3)
    assert_not dr3.overlaps?(dr1)

    assert_not dr1.overlaps?(dr4)
    assert_not dr4.overlaps?(dr1)
  end

  test "can get intersection of overlapping dates" do
    dr1 = DateRange.new("2021-11-05", "2021-11-20")
    dr2 = DateRange.new("2021-11-19", "2021-11-25")
    result = DateRange.new("2021-11-19", "2021-11-20")
    assert_equal result, dr1 & dr2
    assert_equal result, dr2 & dr1
  end

  test "contains is true when one date range contains another" do
    outside = DateRange.new("2021-11-12", "2021-11-18")
    inside = DateRange.new("2021-11-13", "2021-11-15")
    assert outside.contains?(inside)
  end

  test "contains is false when a date range is contained by another" do
    outside = DateRange.new("2021-11-12", "2021-11-18")
    inside = DateRange.new("2021-11-13", "2021-11-15")
    assert_not inside.contains?(outside)
  end

  test "contains is false when date ranges don't even overlap" do
    outside = DateRange.new("2021-11-12", "2021-11-15")
    inside = DateRange.new("2021-11-18", "2021-11-19")
    assert_not inside.contains?(outside)
  end

  test "contains is false when date ranges merely overlap" do
    outside = DateRange.new("2021-11-12", "2021-11-18")
    inside = DateRange.new("2021-11-16", "2021-11-19")
    assert_not inside.contains?(outside)
    assert_not outside.contains?(inside)
  end

  test "include accepts string" do
    dr = DateRange.new("2021-11-01", "2021-11-05")
    assert dr.include?("2021-11-03")
  end

  test "include accepts date" do
    dr = DateRange.new("2021-11-01", "2021-11-05")
    assert dr.include?(Date.parse("2021-11-03"))
  end

  test "include does not accept a date range" do
    dr = DateRange.new("2021-11-01", "2021-11-05")
    victim = DateRange.new("2021-11-02", "2021-11-03")
    assert_raise(Exception) { dr.include?(victim) }
  end

  test "include returns correct values" do
    dr = DateRange.new("2021-11-02", "2021-11-05")
    assert_not dr.include?("2021-11-01")
    assert dr.include?("2021-11-02")
    assert dr.include?("2021-11-03")
    assert dr.include?("2021-11-04")
    assert_not dr.include?("2021-11-05")
    assert_not dr.include?("2021-11-06")
  end

  test "equalsequals returns correct values" do
    dr1 = DateRange.new("2021-11-02", "2021-11-05")
    dr2 = DateRange.new("2021-11-02", "2021-11-05")
    dr3 = DateRange.new("2021-11-02", "2021-11-04")
    dr4 = DateRange.new("2021-11-01", "2021-11-05")
    assert dr1 == dr2
    assert_not dr1 == dr3
    assert_not dr1 == dr4
  end

  test "eql returns correct values" do
    dr1 = DateRange.new("2021-11-02", "2021-11-05")
    dr2 = DateRange.new("2021-11-02", "2021-11-05")
    dr3 = DateRange.new("2021-11-02", "2021-11-04")
    dr4 = DateRange.new("2021-11-01", "2021-11-05")
    assert dr1.eql?(dr2)
    assert_not dr1.eql?(dr3)
    assert_not dr1.eql?(dr4)
  end

  test "hash returns correct values" do
    dr1 = DateRange.new("2021-11-02", "2021-11-05")
    dr2 = DateRange.new("2021-11-02", "2021-11-05")
    dr3 = DateRange.new("2021-11-02", "2021-11-04")
    dr4 = DateRange.new("2021-11-01", "2021-11-05")
    assert_equal dr1.hash, dr2.hash
    assert_not_equal dr1.hash, dr3.hash
    assert_not_equal dr1.hash, dr4.hash
  end

  test "slide handles positive and negative values" do
    dr1 = DateRange.new("2021-11-02", "2021-11-05")
    dr2 = DateRange.new("2021-11-08", "2021-11-11")
    assert_equal dr2, dr1.slide(6)
    assert_equal dr2, dr1.slide(6.days)
    assert_equal dr1, dr2.slide(-6)
    assert_equal dr1, dr2.slide(-6.days)
  end

  test "can iterate through range" do
    dr = DateRange.new("2021-11-02", "2021-11-07")
    expected = Date.parse("2021-11-02")
    seen = 0
    dr.each do |date|
      assert_equal expected, date
      expected += 1.day
      seen += 1
    end
    #
    #  Note that we should *not* have received the 7th in our
    #  iteration, so that should be the next expected date.
    #
    assert_equal Date.parse("2021-11-07"), expected
    assert_equal 5, seen
  end

end
