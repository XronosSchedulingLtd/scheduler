#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class NotifierTest < ActiveSupport::TestCase
  setup do
    today = Date.today
    tomorrow = Date.tomorrow
    @invigilation_property = FactoryBot.create(
      :property,
      name: 'Invigilation')
    @valid_params = {
      start_date: today,
      end_date: tomorrow
    }
    #
    #  And now some staff to do invigilation.
    #
    @staff1 = FactoryBot.create(:staff, email: "staff1@myschool.org.uk")
    @staff2 = FactoryBot.create(:staff, email: "staff2@myschool.org.uk")
    @staff3 = FactoryBot.create(:staff, email: "staff3@myschool.org.uk")
    @all_staff = [@staff1, @staff2, @staff3]
    #
    #  Staff default to wanting notifications.  If they want to
    #  turn them off then they have to create a user account and
    #  set it there.
    #
    @user2 = FactoryBot.create(
      :user,
      email: "staff2@myschool.org.uk",
      invig_daily: false)
    @staff2.reload
    #
    #  And some slots for them to do.
    #
    @event1 = FactoryBot.create(
      :event,
      starts_at: "#{today.to_s(:dmy)} 12:00",
      ends_at: "#{today.to_s(:dmy)} 13:00",
      commitments_to: [@staff1, @invigilation_property])
    @event2 = FactoryBot.create(
      :event,
      starts_at: "#{tomorrow.to_s(:dmy)} 12:00",
      ends_at: "#{tomorrow.to_s(:dmy)} 13:00",
      commitments_to: [@staff2, @invigilation_property])
    @event3 = FactoryBot.create(
      :event,
      starts_at: "#{today.to_s(:dmy)} 16:00",
      ends_at: "#{today.to_s(:dmy)} 17:00",
      commitments_to: [@staff3, @invigilation_property])
    #
    #  This is a second slot for staff3, so we should still get only
    #  3 staff entries.
    #
    @event4 = FactoryBot.create(
      :event,
      starts_at: "#{today.to_s(:dmy)} 08:30",
      ends_at: "#{today.to_s(:dmy)} 10:00",
      commitments_to: [@staff3, @invigilation_property])
  end

  test "can create notifier" do
    notifier = Notifier.new(@valid_params)
    assert notifier.valid?
  end

  test "must have a start date" do
    notifier = Notifier.new(@valid_params.except(:start_date))
    assert_not notifier.valid?
  end

  test "end date can't be before start date" do
    notifier = Notifier.new(@valid_params.merge({end_date: Date.yesterday}))
    assert_not notifier.valid?
  end

  test "default values are as expected" do
    notifier = Notifier.new(@valid_params)
    assert     notifier.send_notifications
    assert_not notifier.check_clashes
  end

  test "can set send_notifications" do
    notifier = Notifier.new(@valid_params)
    assert     notifier.send_notifications
    notifier.send_notifications = "0"
    assert_not notifier.send_notifications
  end

  test "can set check_clashes" do
    notifier = Notifier.new(@valid_params)
    assert_not notifier.check_clashes
    notifier.check_clashes = "1"
    assert     notifier.check_clashes
  end

  test "must execute before sending" do
    notifier = Notifier.new(@valid_params)
    begin
      notifier.do_send(:daily)
      assert false, "Shouldn't get here"
    rescue RuntimeError => e
      assert true, "Should get here"
      assert_equal "Must execute the notifier first.", e.to_s
    end
  end

  test "must execute before notifying" do
    notifier = Notifier.new(@valid_params)
    begin
      notifier.notify_clashes
      assert false, "Shouldn't get here"
    rescue RuntimeError => e
      assert true, "Should get here"
      assert_equal "Must execute the notifier first.", e.to_s
    end
  end

  test "can execute successfully" do
    notifier = Notifier.new(@valid_params)
    assert notifier.execute
    assert_equal 3, notifier.staff_entries.size
    notifier.staff_entries.each do |entry|
      assert entry.instance_of?(Notifier::StaffEntry)
      assert @all_staff.include?(entry.staff)
      if entry.staff == @staff3
        expected = 2
      else
        expected = 1
      end
      assert_equal expected, entry.instances.size 
      if entry.staff == @staff2
        #
        #  We have turned daily notifications off for user2, and thus
        #  staff2.
        #
        assert_not entry.notify?(:daily)
      else
        assert entry.notify?(:daily)
      end
    end
  end


end
