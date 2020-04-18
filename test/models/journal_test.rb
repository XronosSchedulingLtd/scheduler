#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class JournalTest < ActiveSupport::TestCase
  setup do
    @service = FactoryBot.create(:service, name: "My property")
    @user  = FactoryBot.create(:user)
    @staff = FactoryBot.create(:staff)
    @other_eventcategory = FactoryBot.create(:eventcategory)
    @other_staff         = FactoryBot.create(:staff)
    @event = FactoryBot.create(:event,
                               owner: @user,
                               organiser: @staff.element,
                               organiser_ref: "Banana")
    @ewj = FactoryBot.create(:event,
                             owner: @user,
                             organiser: @staff.element,
                             organiser_ref: "Banana")
    @ewj.ensure_journal
    @request = FactoryBot.create(:request, event: @ewj)
    @commitment = FactoryBot.create(:commitment, event: @ewj)
    @note = FactoryBot.create(:note)
    @ufr = FactoryBot.create(:user_form_response)
    @ewj.reload
  end

  test "can create journal" do
    journal = Journal.new
    assert journal.valid?
  end

  test "creating journal for event copies basic data" do
    #
    #  What we're doing here is nearly the same as:
    #    journal = @event.ensure_journal
    #  but we shouldn't really be relying on code in the event
    #  model to test the journal model.
    #
    #  Note that because we don't assign the journal to the event
    #  it won't get saved and there will as yet be no link between
    #  the two.
    #
    journal = Journal.new.populate_from_event(@event)
    assert journal.valid?
    assert_equal @event.body,          journal.event_body
    assert_equal @event.eventcategory, journal.event_eventcategory
    assert_equal @event.owner,         journal.event_owner
    assert_equal @event.starts_at,     journal.event_starts_at
    assert_equal @event.ends_at,       journal.event_ends_at
    assert_equal @event.all_day,       journal.event_all_day
    assert_equal @event.organiser,     journal.event_organiser
    assert_equal @event.organiser_ref, journal.event_organiser_ref
  end

  #
  #  Note that in the following tests what we're testing is that we
  #  can create the journal entries.  We don't necessarily need to
  #  have done the thing which the journal entry will say we have done.
  #
  test "can journal creation" do
    @ewj.journal.event_created(@user, nil, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "event_created", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal cloning" do
    @ewj.journal.event_created(@user, :cloned, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "clone_created", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal wrapping" do
    @ewj.journal.event_created(@user, :wrapped, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "wrapper_created", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal repetition" do
    @ewj.journal.event_created(@user, :repeated, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "repeat_created", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal event body update" do
    @ewj.body = "Updated body"
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "body_text_changed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal event start timing update" do
    @ewj.starts_at = @ewj.starts_at - 1.hour
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "timing_changed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal event end timing update" do
    @ewj.ends_at = @ewj.ends_at + 1.hour
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "timing_changed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal eventcategory change" do
    @ewj.eventcategory = @other_eventcategory
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "category_changed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal organiser change" do
    @ewj.organiser = @other_staff.element
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "organiser_changed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal reference change" do
    @ewj.organiser_ref = "Different reference"
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "organiser_reference_changed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal all changes in one go" do
    @ewj.body = "Updated body"
    @ewj.starts_at = @ewj.starts_at - 1.hour
    @ewj.eventcategory = @other_eventcategory
    @ewj.organiser = @other_staff.element
    @ewj.organiser_ref = "Different reference"
    @ewj.save
    assert @ewj.valid?
    @ewj.journal.event_updated(@user, false)
    assert_equal 5, @ewj.journal.journal_entries.size
    assert_equal "body_text_changed", @ewj.journal.journal_entries[0].entry_type
    assert_equal "timing_changed", @ewj.journal.journal_entries[1].entry_type
    assert_equal "category_changed", @ewj.journal.journal_entries[2].entry_type
    assert_equal "organiser_changed", @ewj.journal.journal_entries[3].entry_type
    assert_equal "organiser_reference_changed", @ewj.journal.journal_entries[4].entry_type
  end

  test "can journal deletion of event" do
    @ewj.journal.event_destroyed(@user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "event_destroyed", @ewj.journal.journal_entries[0].entry_type
    #
    #  And the journal survives.
    #
    journal = @ewj.journal
    @ewj.destroy
    journal.reload
    assert_nil journal.event
    assert_equal 1, journal.journal_entries.size
  end

  test "can journal commitment added" do
    @ewj.journal.commitment_added(@commitment, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_added", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal commitment removed" do
    @ewj.journal.commitment_removed(@commitment, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_removed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal commitment approved" do
    @ewj.journal.commitment_approved(@commitment, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "commitment_approved", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal commitment rejected" do
    @ewj.journal.commitment_rejected(@commitment, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "commitment_rejected", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal commitment noted" do
    @ewj.journal.commitment_noted(@commitment, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "commitment_noted", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal commitment reset" do
    @ewj.journal.commitment_reset(@commitment, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "commitment_reset", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal note added" do
    @ewj.journal.note_added(@note, nil, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "note_added", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal note updated" do
    @ewj.journal.note_updated(@note, nil, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "note_updated", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal form completed" do
    @ewj.journal.form_completed(@ufr, nil, @user, false)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "form_completed", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal repeated from" do
    @ewj.journal.repeated_from(@user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "repeated_from", @ewj.journal.journal_entries[0].entry_type
  end

  test "can journal resource request created" do
    @ewj.journal.resource_request_created(@request, @user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_created",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal "Quantity: 1", @ewj.journal.journal_entries[0].details
  end

  test "can journal resource request destroyed" do
    @ewj.journal.resource_request_destroyed(@request, @user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_destroyed",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal "Quantity: 1", @ewj.journal.journal_entries[0].details
  end

  test "can journal resource request incremented" do
    #
    #  Note that we call the journaling code *after* doing the
    #  increment, so this is the new value.
    #
    @request.quantity = 2
    @ewj.journal.resource_request_incremented(@request, @user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_incremented",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal "From 1 to 2", @ewj.journal.journal_entries[0].details
  end

  test "can journal resource request decremented" do
    @request.quantity = 4
    @ewj.journal.resource_request_decremented(@request, @user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_decremented",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal "From 5 to 4", @ewj.journal.journal_entries[0].details
  end

  test "can journal resource request adjusted" do
    @request.quantity = 3
    @ewj.journal.resource_request_adjusted(@request, 5, @user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_adjusted",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal "From 5 to 3", @ewj.journal.journal_entries[0].details
  end

  test "can journal resource request allocated" do
    @ewj.journal.resource_request_allocated(@request, @user, @service.element)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_allocated",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal @service.element.name, @ewj.journal.journal_entries[0].details
  end

  test "can journal resource request deallocated" do
    @ewj.journal.resource_request_deallocated(@request, @user, @service.element)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_deallocated",
      @ewj.journal.journal_entries[0].entry_type
    assert_equal @service.element.name, @ewj.journal.journal_entries[0].details
  end

  test "can journal request reconfirmation" do
    @ewj.journal.resource_request_reconfirmed(@request, @user)
    assert_equal 1, @ewj.journal.journal_entries.size
    assert_equal "resource_request_reconfirmed", @ewj.journal.journal_entries[0].entry_type
    assert_equal "Quantity: 1", @ewj.journal.journal_entries[0].details
  end

end
