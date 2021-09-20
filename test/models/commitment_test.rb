#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class CommitmentTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @location1 = FactoryBot.create(:location)
    @location2 = FactoryBot.create(:location)
    @locking_property1 = FactoryBot.create(:property, locking: true)
    @locking_property2 = FactoryBot.create(:property, locking: true)
    @user = FactoryBot.create(:user)
    @valid_params1 = {
      event: @event,
      element: @location1.element
    }
    @valid_params2 = {
      event: @event,
      element: @location2.element
    }
  end

  test "can create commitment with valid params" do
    commitment = Commitment.create(@valid_params1)
    assert commitment.valid?, "Testing commitment valid"
  end

  test "can't create second commitment with same params" do
    commitment1 = Commitment.create(@valid_params1)
    assert commitment1.valid?
    commitment2 = Commitment.new(@valid_params1)
    assert_not commitment2.valid?
  end

  test "commitment requires event" do
    commitment = Commitment.create(@valid_params1.merge(event: nil))
    assert_not commitment.valid?
  end

  test "commitment requires element" do
    commitment = Commitment.create(@valid_params1.merge(element: nil))
    assert_not commitment.valid?
  end

  test "commitment must be unique" do
    commitment1 = Commitment.create(@valid_params1)
    assert commitment1.valid?
    commitment2 = Commitment.create(@valid_params1)
    assert_not commitment2.valid?
  end

  test 'adding an ordinary commitment does not make an event incomplete' do
    assert @event.complete?
    commitment = Commitment.create(@valid_params1)
    @event.reload
    assert @event.complete?
  end

  test 'adding a tentative commitment makes an event incomplete' do
    assert @event.complete?
    commitment = Commitment.create(@valid_params1.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
  end

  test 'removing only tentative commitment makes an event complete' do
    assert @event.complete?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    commitment1.destroy
    @event.reload
    assert @event.complete?
  end

  test 'removing one tentative commitment out of two does not make an event complete' do
    assert @event.complete?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    commitment2 = Commitment.create(@valid_params2.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    commitment1.destroy
    @event.reload
    assert_not @event.complete?
  end

  test 'removing second tentative commitment makes an event complete' do
    assert @event.complete?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    commitment2 = Commitment.create(@valid_params2.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    commitment1.destroy
    @event.reload
    assert_not @event.complete?
    commitment2.destroy
    @event.reload
    assert @event.complete?
  end

  test 'approving a commitment makes the event constrained' do
    assert @event.complete?
    assert_not @event.constrained?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    assert_not @event.constrained?
    commitment1.approve_and_save!(@user)
    @event.reload
    assert @event.complete?
    assert @event.constrained?
  end

  test 'un-approving a commitment makes the event unconstrained' do
    assert @event.complete?
    assert_not @event.constrained?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    assert_not @event.constrained?
    commitment1.approve_and_save!(@user)
    @event.reload
    assert @event.complete?
    assert @event.constrained?
    commitment1.revert_and_save!
    @event.reload
    assert_not @event.complete?
    assert_not @event.constrained?
  end

  test 'removing approved commitment makes event unconstrained' do
    assert @event.complete?
    assert_not @event.constrained?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    assert_not @event.constrained?
    commitment1.approve_and_save!(@user)
    @event.reload
    assert @event.complete?
    assert @event.constrained?
    commitment1.destroy
    @event.reload
    assert @event.complete?
    assert_not @event.constrained?
  end

  test 'removing one approved commitment does not make event unconstrained' do
    assert @event.complete?
    assert_not @event.constrained?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    commitment2 = Commitment.create(@valid_params2.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    assert_not @event.constrained?
    commitment1.approve_and_save!(@user)
    commitment2.approve_and_save!(@user)
    @event.reload
    assert @event.complete?
    assert @event.constrained?
    commitment1.destroy
    @event.reload
    assert @event.complete?
    assert @event.constrained?
  end

  test 'removing second approved commitment makes event unconstrained' do
    assert @event.complete?
    assert_not @event.constrained?
    commitment1 = Commitment.create(@valid_params1.merge({status: :requested}))
    commitment2 = Commitment.create(@valid_params2.merge({status: :requested}))
    @event.reload
    assert_not @event.complete?
    assert_not @event.constrained?
    commitment1.approve_and_save!(@user)
    commitment2.approve_and_save!(@user)
    @event.reload
    assert @event.complete?
    assert @event.constrained?
    commitment1.destroy
    @event.reload
    assert @event.complete?
    assert @event.constrained?
    commitment2.destroy
    @event.reload
    assert @event.complete?
    assert_not @event.constrained?
  end

  test 'approving a normal commitment does not lock the event' do
    assert_not @event.locked?
    commitment = Commitment.create(@valid_params1.merge({status: :requested}))
    @event.reload
    assert_not @event.locked?
    commitment.approve_and_save!(@user)
    @event.reload
    assert_not @event.locked?
  end

  test 'adding an uncontrolled commitment locks the event' do
    assert_not @event.locked?
    commitment = Commitment.create({
      event: @event,
      element: @locking_property1.element
    })
    @event.reload
    assert @event.locked?
  end

  test 'removing uncontrolled commitment unlocks the event' do
    assert_not @event.locked?
    commitment = Commitment.create({
      event: @event,
      element: @locking_property1.element
    })
    @event.reload
    assert @event.locked?
    commitment.destroy
    @event.reload
    assert_not @event.locked?
  end

  test 'removing one of two commitments does not unlock the event' do
    assert_not @event.locked?
    commitment1 = Commitment.create({
      event: @event,
      element: @locking_property1.element
    })
    commitment2 = Commitment.create({
      event: @event,
      element: @locking_property2.element
    })
    @event.reload
    assert @event.locked?
    commitment1.destroy
    @event.reload
    assert @event.locked?
  end

  test 'removing both commitments does unlock the event' do
    assert_not @event.locked?
    commitment1 = Commitment.create({
      event: @event,
      element: @locking_property1.element
    })
    commitment2 = Commitment.create({
      event: @event,
      element: @locking_property2.element
    })
    @event.reload
    assert @event.locked?
    commitment1.destroy
    @event.reload
    assert @event.locked?
    commitment2.destroy
    @event.reload
    assert_not @event.locked?
  end

  test 'approving a suitable commitment locks the event' do
    assert_not @event.locked?
    commitment = Commitment.create({
      event: @event,
      element: @locking_property1.element,
      status: :requested
    })
    @event.reload
    assert_not @event.locked?
    commitment.approve_and_save!(@user)
    @event.reload
    assert @event.locked?
  end

  test 'unapproving a suitable commitment unlocks the event' do
    assert_not @event.locked?
    commitment = Commitment.create({
      event: @event,
      element: @locking_property1.element,
      status: :requested
    })
    @event.reload
    assert_not @event.locked?
    commitment.approve_and_save!(@user)
    @event.reload
    assert @event.locked?
    commitment.revert_and_save!
    @event.reload
    assert_not @event.locked?
  end

  test 'deleting approved commitment unlocks the event' do
    assert_not @event.locked?
    commitment = Commitment.create({
      event: @event,
      element: @locking_property1.element,
      status: :requested
    })
    @event.reload
    assert_not @event.locked?
    commitment.approve_and_save!(@user)
    @event.reload
    assert @event.locked?
    commitment.destroy
    @event.reload
    assert_not @event.locked?
  end

  test 'unapproving one of two commitments does not unlock the event' do
    assert_not @event.locked?
    commitment1 = Commitment.create({
      event: @event,
      element: @locking_property1.element,
      status: :requested
    })
    commitment2 = Commitment.create({
      event: @event,
      element: @locking_property2.element,
      status: :requested
    })
    @event.reload
    assert_not @event.locked?
    commitment1.approve_and_save!(@user)
    commitment2.approve_and_save!(@user)
    @event.reload
    assert @event.locked?
    commitment1.revert_and_save!
    @event.reload
    assert @event.locked?
  end

  test 'unapproving both commitments does unlock the event' do
    assert_not @event.locked?
    commitment1 = Commitment.create({
      event: @event,
      element: @locking_property1.element,
      status: :requested
    })
    commitment2 = Commitment.create({
      event: @event,
      element: @locking_property2.element,
      status: :requested
    })
    @event.reload
    assert_not @event.locked?
    commitment1.approve_and_save!(@user)
    commitment2.approve_and_save!(@user)
    @event.reload
    assert @event.locked?
    commitment1.revert_and_save!
    @event.reload
    assert @event.locked?
    commitment2.revert_and_save!
    @event.reload
    assert_not @event.locked?
  end

  test 'can detect and list simple clashes' do
    #
    #  Original event defaults to 1 hour long.
    #
    other_event = FactoryBot.create(:event,
                                    starts_at: @event.starts_at + 30.minutes,
                                    ends_at: @event.ends_at + 30.minutes)
    commitment1 = Commitment.create(@valid_params1)
    assert commitment1.valid?
    assert_not commitment1.has_simple_clash?
    commitment2 = Commitment.create(@valid_params1.merge({event: other_event}))
    assert commitment2.valid?
    assert commitment1.has_simple_clash?
    assert_equal "#{other_event.body} (#{other_event.duration_or_all_day_string})", commitment1.text_of_clashes
    clashing_commitments = commitment1.clashing_commitments
    assert clashing_commitments.include?(commitment2)
    assert_equal 1, clashing_commitments.size
  end

  test "passes through overlaps? correctly" do
    base_time = Time.zone.now
    event1 = FactoryBot.create(:event,
                               starts_at: base_time,
                               ends_at: base_time + 10.minutes)
    commitment1 = FactoryBot.create(:commitment, event: event1)
    event2 = FactoryBot.create(:event,
                               starts_at: base_time + 5.minutes,
                               ends_at: base_time + 15.minutes)
    commitment2 = FactoryBot.create(:commitment, event: event2)
    event3 = FactoryBot.create(:event,
                               starts_at: base_time + 10.minutes,
                               ends_at: base_time + 20.minutes)
    commitment3 = FactoryBot.create(:commitment, event: event3)
    assert commitment1.overlaps?(commitment2)
    assert commitment2.overlaps?(commitment1)
    assert commitment2.overlaps?(commitment3)
    assert commitment3.overlaps?(commitment2)
    assert_not commitment1.overlaps?(commitment3)
    assert_not commitment3.overlaps?(commitment1)
  end

end


