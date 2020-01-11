require 'test_helper'

class ExamRoomManagerTest < ActiveSupport::TestCase

  setup do
    #
    #  These are actually exactly the same as those which the
    #  factory defaults to, but we need to set them explicitly
    #  to avoid changes to the factory breaking our test.
    #
    @our_rota_slot_times = [
      ["08:30", "09:00"],         # Preparation
      ["09:00", "09:20"],         # Assembly
      ["09:25", "10:15"],         # 1
      ["10:20", "11:10"],         # 2
      ["11:10", "11:30"],         # Break
      ["11:30", "12:20"],         # 3
      ["12:25", "13:15"],         # 4
      ["13:15", "14:00"],         # Lunch
      ["14:00", "14:45"],         # 5
      ["14:50", "15:35"],         # 6
      ["15:40", "16:30"],         # 7
      ["16:30", "17:00"]          # For really long exams
    ]
    @selector_property = FactoryBot.create(:property)
    @rota_template = FactoryBot.create(:rota_template,
                                       slots: @our_rota_slot_times)
    @exam_cycle =
      FactoryBot.create(
        :exam_cycle,
        default_rota_template: @rota_template,
        selector_element: @selector_property.element,
        starts_on: Date.today,
        ends_on: Date.tomorrow)
    @location1 = FactoryBot.create(:location, name: "Location 1")
    @location2 = FactoryBot.create(:location, name: "Location 2")
    #
    #  These times come from masking the rota template with the
    #  actual times of the defining exam events.
    #
    full_day_of_times = [
      #
      #  Morning session
      #
      ["08:45", "09:00"],
      ["09:00", "09:20"],
      ["09:25", "10:15"],
      ["10:20", "11:10"],
      ["11:10", "11:30"],
      ["11:30", "12:00"],
      #
      #  Afternoon session
      #
      ["13:30", "14:00"],
      ["14:00", "14:45"],
      ["14:50", "15:35"],
      ["15:40", "16:00"]
    ]
    just_afternoon_times = [
      ["13:30", "14:00"],
      ["14:00", "14:45"],
      ["14:50", "15:35"],
      ["15:40", "16:00"]
    ]
    @resulting_times_today = {
      @location1 => full_day_of_times,
      @location2 => full_day_of_times
    }
    @resulting_times_tomorrow = {
      @location1 => just_afternoon_times,
      @location2 => []
    }
    #
    #  Now we need some events defining exam sessions.
    #
    #  Location 1 is used today in the am and pm, and tomorrow pm
    #  Location 2 is used today in the am and pm
    #
    @event1 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("08:45").on(Date.today),
        ends_at: Tod::TimeOfDay.parse("12:00").on(Date.today),
        commitments_to: [@selector_property, @location1, @location2])
    @event2 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("13:30").on(Date.today),
        ends_at: Tod::TimeOfDay.parse("16:00").on(Date.today),
        commitments_to: [@selector_property, @location1, @location2])
    @event3 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("13:30").on(Date.tomorrow),
        ends_at: Tod::TimeOfDay.parse("16:00").on(Date.tomorrow),
        commitments_to: [@selector_property, @location1])
    @erm = ExamRoomManager.new(@exam_cycle)
    @eventsource = Eventsource.find_by(name: "RotaSlot")
    @eventcategory = Eventcategory.cached_category("Invigilation")
  end

  test "have source and category" do
    assert_not_nil @eventsource
    assert_not_nil @eventcategory
  end

  test "can create erm" do
    assert_not_nil @erm
  end

  test "can iterate through rooms" do
    num_rooms = 0
    @erm.each_room_record do |room_record|
      num_rooms += 1
    end
    assert_equal 2, num_rooms
  end

  test "each room is used for right interval" do
    @erm.each_room_record do |room_record|
      case room_record.location
      when @location1
        assert_equal Date.today, room_record.first_date
        assert_equal Date.tomorrow, room_record.last_date
      when @location2
        assert_equal Date.today, room_record.first_date
        assert_equal Date.today, room_record.last_date
      else
        assert false, "Got a room I wasn't expecting"
      end
    end
  end

  test "can generate proto events" do
    @erm.generate_proto_events(@eventcategory, @eventsource)
    #
    #  One proto event per room which we've used.
    #
    assert_equal 2, @exam_cycle.proto_events.count
    @exam_cycle.proto_events.each do |pe|
      case pe.location_id
      when @location1.element.id
        assert_equal Date.today,    pe.starts_on
        assert_equal Date.tomorrow, pe.ends_on
      when @location2.element.id
        assert_equal Date.today,    pe.starts_on
        assert_equal Date.today,    pe.ends_on
      else
        assert false, "Unexpected room in proto event"
      end
    end
  end

  test "erm generates correct event timing" do
    @erm.generate_proto_events(@eventcategory, @eventsource)
    @exam_cycle.proto_events.each do |pe|
      slots_seen = 0
      @erm.slots_for(pe, Date.today) do |slot|
        assert timing_in_list?(@resulting_times_today[pe.location],
                               slot)
        slots_seen += 1
      end
      assert_equal @resulting_times_today[pe.location].size, slots_seen
      slots_seen = 0
      @erm.slots_for(pe, Date.tomorrow) do |slot|
        assert timing_in_list?(@resulting_times_tomorrow[pe.location],
                               slot)
        slots_seen += 1
      end
      assert_equal @resulting_times_tomorrow[pe.location].size, slots_seen
    end
  end

  test "erm copes if rota template has been deleted" do
    @rota_template.destroy
    @exam_cycle.reload
    @erm.generate_proto_events(@eventcategory, @eventsource)
    assert_equal 0, @exam_cycle.proto_events.count
  end

  test "overlapping exam sessions are merged in creating timings" do
    #
    #  This event overlaps with @event3.  The end result should be to
    #  produce a single set of invigilation slots running from
    #  the start of event4 (12:00) to the end of event @event3 (16:00)
    #
    event4 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("12:00").on(Date.tomorrow),
        ends_at: Tod::TimeOfDay.parse("14:00").on(Date.tomorrow),
        commitments_to: [@selector_property, @location1])
    extended_afternoon_times = [
      ["12:00", "12:20"],
      ["12:25", "13:15"],
      ["13:15", "14:00"],
      ["14:00", "14:45"],
      ["14:50", "15:35"],
      ["15:40", "16:00"]
    ]
    #
    #  Need a new erm because we've created an extra event.
    #
    erm = ExamRoomManager.new(@exam_cycle)
    erm.generate_proto_events(@eventcategory, @eventsource)
    @exam_cycle.proto_events.each do |pe|
      if pe.location == @location1
        slots_seen = 0
        erm.slots_for(pe, Date.tomorrow) do |slot|
          assert timing_in_list?(extended_afternoon_times, slot)
          slots_seen += 1
        end
        assert_equal extended_afternoon_times.size, slots_seen
      end
    end
  end

  test "can get 3 invigilation slots from one original slot" do
    our_rota_slot_times = [
      ["14:00", "14:45"]    # Just the one
    ]
    rota_template = FactoryBot.create(:rota_template,
                                      slots: our_rota_slot_times)
    #
    #  Use a completely blank day.
    #
    date = Date.today + 2.days
    exam_cycle =
      FactoryBot.create(
        :exam_cycle,
        default_rota_template: rota_template,
        selector_element: @selector_property.element,
        starts_on: date,
        ends_on: date)
    event1 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("13:50").on(date),
        ends_at: Tod::TimeOfDay.parse("14:10").on(date),
        commitments_to: [@selector_property, @location1])
    event2 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("14:15").on(date),
        ends_at: Tod::TimeOfDay.parse("14:30").on(date),
        commitments_to: [@selector_property, @location1])
    event3 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("14:35").on(date),
        ends_at: Tod::TimeOfDay.parse("15:00").on(date),
        commitments_to: [@selector_property, @location1])
    resulting_times = [
      ["14:00", "14:10"],
      ["14:15", "14:30"],
      ["14:35", "14:45"]
    ]
    erm = ExamRoomManager.new(exam_cycle)
    erm.generate_proto_events(@eventcategory, @eventsource)
    exam_cycle.proto_events.each do |pe|
      if pe.location == @location1
        slots_seen = 0
        erm.slots_for(pe, date) do |slot|
          assert timing_in_list?(resulting_times, slot)
          slots_seen += 1
        end
        assert_equal resulting_times.size, slots_seen
      end
    end
  end

  test "overlapping rota slots produce duplicates" do
    our_rota_slot_times = [
      ["14:00", "14:45"],
      ["14:30", "15:00"]
    ]
    rota_template = FactoryBot.create(:rota_template,
                                      slots: our_rota_slot_times)
    #
    #  Use a completely blank day.
    #
    date = Date.today + 2.days
    exam_cycle =
      FactoryBot.create(
        :exam_cycle,
        default_rota_template: rota_template,
        selector_element: @selector_property.element,
        starts_on: date,
        ends_on: date)
    event1 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("13:50").on(date),
        ends_at: Tod::TimeOfDay.parse("14:10").on(date),
        commitments_to: [@selector_property, @location1])
    event2 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("14:15").on(date),
        ends_at: Tod::TimeOfDay.parse("14:30").on(date),
        commitments_to: [@selector_property, @location1])
    event3 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("14:35").on(date),
        ends_at: Tod::TimeOfDay.parse("15:20").on(date),
        commitments_to: [@selector_property, @location1])
    resulting_times = [
      ["14:00", "14:10"],
      ["14:15", "14:30"],
      ["14:35", "14:45"],
      ["14:35", "15:00"]
    ]
    erm = ExamRoomManager.new(exam_cycle)
    erm.generate_proto_events(@eventcategory, @eventsource)
    exam_cycle.proto_events.each do |pe|
      if pe.location == @location1
        slots_seen = 0
        erm.slots_for(pe, date) do |slot|
          assert timing_in_list?(resulting_times, slot)
          slots_seen += 1
        end
        assert_equal resulting_times.size, slots_seen
      end
    end
  end

  private

  def timing_in_list?(timings, item)
    #
    #  Hard to do this efficiently because the list is of pairs of
    #  strings, whilst the item will have two TimeOfDay items.
    #
    starts_at_str = item.starts_at_tod.strftime("%H:%M")
    ends_at_str   = item.ends_at_tod.strftime("%H:%M")
    #puts "Checking #{starts_at_str} to #{ends_at_str}"
    #
    #  Double negative to turn it into a boolean.
    #
    entry = timings.detect {|t| t[0] == starts_at_str && t[1] == ends_at_str}
    unless entry
      puts "Can't find #{starts_at_str} to #{ends_at_str}"
    end

    !!entry
  end

end
