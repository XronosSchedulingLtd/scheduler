require 'test_helper'

class FreeSlotFinderTest < ActiveSupport::TestCase

  setup do
    @staff1 = FactoryBot.create(:staff)
    @staff2 = FactoryBot.create(:staff)
    @staff3 = FactoryBot.create(:staff)

    @element1 = @staff1.element
    @element2 = @staff2.element
    @element3 = @staff3.element

    @elements = [@element1, @element2, @element3]

    @day1 = Date.parse("2017-01-01")
    @event_for_all =
      FactoryBot.create(:event,
                        starts_at: Tod::TimeOfDay.parse("08:00").on(@day1),
                        ends_at: Tod::TimeOfDay.parse("10:30").on(@day1),
                        commitments_to: [@staff1, @staff2, @staff3])
    @event_for_1 =
      FactoryBot.create(:event,
                        starts_at: Tod::TimeOfDay.parse("11:30").on(@day1),
                        ends_at: Tod::TimeOfDay.parse("14:00").on(@day1),
                        commitments_to: [@staff1])
    @event_for_2 =
      FactoryBot.create(:event,
                        starts_at: Tod::TimeOfDay.parse("15:30").on(@day1),
                        ends_at: Tod::TimeOfDay.parse("18:00").on(@day1),
                        commitments_to: [@staff1])
  end

  test "can create a free slot finder" do
    fsf = FreeSlotFinder.new(@elements, 60, "08:30", "17:00")
    assert_not_nil fsf
  end

  test "non-elements produce exception" do
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new([@element1, :able], 60, "08:30", "17:00")
    }
    assert_match /Not an element/, err.message
  end

  test "mins_required must be a positive integer" do
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, :able, "08:30", "17:00")
    }
    assert_match /must be a positive integer/, err.message
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, -8, "08:30", "17:00")
    }
    assert_match /must be a positive integer/, err.message
  end

  test "times can be pre-cooked" do
    fsf = FreeSlotFinder.new(@elements,
                             60,
                             Tod::TimeOfDay.parse("08:30"),
                             Tod::TimeOfDay.parse("17:00"))
    assert_not_nil fsf
  end

  test "but they must be times" do
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, 60, :able, "17:00")
    }
    assert_match /Invalid start time/, err.message
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, 60, "able", "17:00")
    }
    assert_match /Invalid time of day string/, err.message
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, 60, "08:30", :able)
    }
    assert_match /Invalid end time/, err.message
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, 60, "08:30", "able")
    }
    assert_match /Invalid time of day string/, err.message
  end

  test "time slot can't be backwards" do
    err = assert_raise(ArgumentError) {
      fsf = FreeSlotFinder.new(@elements, 60, "17:00", "08:30")
    }
    assert_match /Backwards time slot/, err.message
  end

  test "can find free slots" do
    fsf = FreeSlotFinder.new(@elements, 60, "08:30", "17:00")
    fs = fsf.slots_on(@day1)
    assert fs.instance_of?(TimeSlotSet)
    assert_not fs.empty?
    assert_equal @day1, fs.date
    assert_equal 2, fs.size
    assert_equal "10:30 - 11:30", fs[0].to_s
    assert_equal "14:00 - 15:30", fs[1].to_s
  end

  test "another event blocks one out" do
    extra_event =
      FactoryBot.create(:event,
                        starts_at: Tod::TimeOfDay.parse("10:00").on(@day1),
                        ends_at: Tod::TimeOfDay.parse("12:00").on(@day1),
                        commitments_to: [@staff1])
    fsf = FreeSlotFinder.new(@elements, 60, "08:30", "17:00")
    fs = fsf.slots_on(@day1)
    assert fs.instance_of?(TimeSlotSet)
    assert_not fs.empty?
    assert_equal @day1, fs.date
    assert_equal 1, fs.size
    assert_equal "14:00 - 15:30", fs[0].to_s
  end

  test "but not if its a non-busy event" do
    extra_event =
      FactoryBot.create(:event,
                        eventcategory: eventcategories(:unbusy),
                        starts_at: Tod::TimeOfDay.parse("10:00").on(@day1),
                        ends_at: Tod::TimeOfDay.parse("12:00").on(@day1),
                        commitments_to: [@staff1])
    fsf = FreeSlotFinder.new(@elements, 60, "08:30", "17:00")
    fs = fsf.slots_on(@day1)
    assert fs.instance_of?(TimeSlotSet)
    assert_not fs.empty?
    assert_equal @day1, fs.date
    assert_equal 2, fs.size
    assert_equal "10:30 - 11:30", fs[0].to_s
    assert_equal "14:00 - 15:30", fs[1].to_s
  end

  test "free slot can be at start of day" do
    fsf = FreeSlotFinder.new(@elements, 60, "07:00", "17:00")
    fs = fsf.slots_on(@day1)
    assert fs.instance_of?(TimeSlotSet)
    assert_not fs.empty?
    assert_equal @day1, fs.date
    assert_equal 3, fs.size
    assert_equal "07:00 - 08:00", fs[0].to_s
    assert_equal "10:30 - 11:30", fs[1].to_s
    assert_equal "14:00 - 15:30", fs[2].to_s
  end

  test "free slot can be at end of day" do
    fsf = FreeSlotFinder.new(@elements, 60, "08:30", "19:00")
    fs = fsf.slots_on(@day1)
    assert fs.instance_of?(TimeSlotSet)
    assert_not fs.empty?
    assert_equal @day1, fs.date
    assert_equal 3, fs.size
    assert_equal "10:30 - 11:30", fs[0].to_s
    assert_equal "14:00 - 15:30", fs[1].to_s
    assert_equal "18:00 - 19:00", fs[2].to_s
  end

  test "given a group we check individual members" do
    group = FactoryBot.create(:group, starts_on: @day1)
    group.add_member(@element1, @day1)
    group.add_member(@element2, @day1)
    group.add_member(@element3, @day1)

    fsf = FreeSlotFinder.new([group.element], 60, "08:30", "17:00")
    fs = fsf.slots_on(@day1)
    assert fs.instance_of?(TimeSlotSet)
    assert_not fs.empty?
    assert_equal @day1, fs.date
    assert_equal 2, fs.size
    assert_equal "10:30 - 11:30", fs[0].to_s
    assert_equal "14:00 - 15:30", fs[1].to_s
  end

end

