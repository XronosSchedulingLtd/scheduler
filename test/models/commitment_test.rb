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

end


