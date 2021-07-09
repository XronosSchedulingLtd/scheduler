require 'test_helper'

class RotaTemplateTest < ActiveSupport::TestCase
  #
  #  Note the subtle difference between calling RotaTemplate#rota_slots
  #  and RotaTemplate#slots.  The former is doing a direct access to the
  #  underlying linked models, whilst the latter is intended to facilitate
  #  easy updates from JavaScript code via a controller.
  #
  #  The former gives you an array of RotaSlot models, whilst the latter
  #  gives you an array of simple hashes (containing much the same information,
  #  but stripped of all unnecessary bits).
  #
  #  The big difference is that you can do RotaTemplate#slots= to write
  #  back a modified (or completely new) set.  The model will then take
  #  care of amending, deleting and creating the underlying RotaSlots as
  #  required.
  #
  setup do
    @rtt = FactoryBot.create(:rota_template_type)
    @valid_attributes = {
      name: "Able baker",
      rota_template_type: @rtt
    }
  end

  test "can create valid rota template" do
    rt = RotaTemplate.create(@valid_attributes)
    assert rt.valid?
  end

  test "name is required" do
    rt = RotaTemplate.create(@valid_attributes.except(:name))
    assert_not rt.valid?
  end

  test "rota template type is required" do
    rt = RotaTemplate.create(@valid_attributes.except(:rota_template_type))
    assert_not rt.valid?
  end

  test "factory creates rota template with slots" do
    rt = FactoryBot.create(:rota_template)
    #
    #  I'd like to ask FactoryBot how many it thinks it is creating,
    #  but I've yet to find a way of doing that.
    #
    assert_equal 12, rt.rota_slots.count
  end

  test "but can do it without" do
    rt = FactoryBot.create(:rota_template, :no_slots)
    assert_equal 0, rt.rota_slots.count
  end

  test "or provide custom slots" do
    rt = FactoryBot.create(
      :rota_template,
      slots: [
        ["11:10", "11:30"],
        ["11:30", "12:20"],
        ["12:25", "13:15"]
      ])
    assert_equal 3, rt.rota_slots.count
  end

  test "can read all slots in one go" do
    rt = FactoryBot.create(:rota_template)
    assert_equal 12, rt.slots.count
  end

  test "can update just one slot" do
    rt = FactoryBot.create(:rota_template)
    before_sorted_rota_slots = rt.rota_slots.sort
    before_slot_ids = before_sorted_rota_slots.map(&:id)
    before_last_updated = before_sorted_rota_slots.map(&:updated_at)
    #
    #  Pretend to travel one minute into the future in order to be sure
    #  of detecting changes to the modified_at field if there are any.
    #
    #  Without this, the test can run so quickly that although the
    #  record has been updated, the two times look the same.
    #
    travel 1.minute
    #
    #  And now modify just one.
    #
    slots = rt.slots
    assert_equal 12, slots.count
    #
    #  First slot, change first day to the opposite of what it was
    #  before.  As the times are unchanged this should result in a
    #  modified RotaSlot record rather than a new one.
    #
    slots[0][:days][0] = !slots[0][:days][0]
    rt.slots = slots
    #
    #  And see that that has worked.
    #
    after_sorted_rota_slots = rt.rota_slots.sort
    after_slot_ids = after_sorted_rota_slots.map(&:id)
    after_last_updated = after_sorted_rota_slots.map(&:updated_at)
    assert_equal before_slot_ids, after_slot_ids
    assert_not_equal before_last_updated[0], after_last_updated[0]
    (1..11).each do |i|
      assert_equal before_last_updated[i], after_last_updated[i]
    end
  end

  test "bad timings affect no slots" do
    rt = FactoryBot.create(:rota_template)
    before_sorted_rota_slots = rt.rota_slots.sort
    before_slot_ids = before_sorted_rota_slots.map(&:id)
    before_last_updated = before_sorted_rota_slots.map(&:updated_at)
    #
    #  Pretend to travel one minute into the future in order to be sure
    #  of detecting changes to the modified_at field if there are any.
    #
    #  Without this, the test can run so quickly that although the
    #  record has been updated, the two times look the same.
    #
    travel 1.minute
    #
    #  And now modify just one.
    #
    slots = rt.slots
    assert_equal 12, slots.count
    #
    #  First slot, change first day to the opposite of what it was
    #  before.  As the times are unchanged this should result in a
    #  modified RotaSlot record rather than a new one.
    #
    #  ...but!  Put an invalid change in the second slot.  This should
    #  cause a rollback and so a change to neither.
    #
    slots[0][:days][0] = !slots[0][:days][0]
    slots[1][:ends_at] = "05:00"  # Before the start time.
    assert_raise(ArgumentError) { rt.slots = slots }
    #
    #  And see that that has worked.
    #
    after_sorted_rota_slots = rt.rota_slots.sort
    after_slot_ids = after_sorted_rota_slots.map(&:id)
    after_last_updated = after_sorted_rota_slots.map(&:updated_at)
    assert_equal before_slot_ids, after_slot_ids
    (0..11).each do |i|
      assert_equal before_last_updated[i], after_last_updated[i]
    end
  end

  test "change of timing creates a new slot" do
    rt = FactoryBot.create(:rota_template)
    before_sorted_rota_slots = rt.rota_slots.sort
    before_slot_ids = before_sorted_rota_slots.map(&:id)
    before_last_updated = before_sorted_rota_slots.map(&:updated_at)
    #
    #  Pretend to travel one minute into the future in order to be sure
    #  of detecting changes to the modified_at field if there are any.
    #
    #  Without this, the test can run so quickly that although the
    #  record has been updated, the two times look the same.
    #
    travel 1.minute
    #
    #  And now modify just one.
    #
    slots = rt.slots
    assert_equal 12, slots.count
    #
    #  First slot, change first day to the opposite of what it was
    #  before.  As the times are unchanged this should result in a
    #  modified RotaSlot record rather than a new one.
    #
    slots[0][:starts_at] = "05:00"  # Really early
    rt.slots = slots
    #
    #  And see that that has worked.
    #
    after_sorted_rota_slots = rt.rota_slots.sort
    after_slot_ids = after_sorted_rota_slots.map(&:id)
    after_last_updated = after_sorted_rota_slots.map(&:updated_at)
    assert_not_equal before_slot_ids[0], after_slot_ids[0]
    (1..11).each do |i|
      assert_equal before_slot_ids[i], after_slot_ids[i]
    end
    (1..11).each do |i|
      assert_equal before_last_updated[i], after_last_updated[i]
    end
  end

  test "can find slot for a given time" do
    rt = FactoryBot.create(:rota_template)
    assert_not_nil rt.covering_slot(1, Tod::TimeOfDay.parse("11:04"))
    assert_nil rt.covering_slot(1, Tod::TimeOfDay.parse("12:22"))
  end

  test "can clone a template" do
    rt = FactoryBot.create(:rota_template)
    assert_difference("RotaTemplate.count") do
      new_rt = rt.do_clone
      assert_equal 12, new_rt.slots.count
    end
  end

  test "can specify a name when cloning" do
    rt = FactoryBot.create(:rota_template)
    assert_difference("RotaTemplate.count") do
      new_rt = rt.do_clone("Name of clone")
      assert_equal "Name of clone", new_rt.name
    end
  end

end
