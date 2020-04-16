require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  setup do
    @location1 = FactoryBot.create(:location, weighting: 150)
    @location2 = FactoryBot.create(:location)
    @location3 = FactoryBot.create(:location, weighting: 130)
    @location4 = FactoryBot.create(:location, weighting: 129)
    @all_locations = [@location1, @location2, @location3, @location4]
    @heavy_locations = [@location1, @location3]
    @light_locations = [@location2, @location4]

    @event = FactoryBot.create(:event, commitments_to: @all_locations)
  end

  test 'must have an entity' do
    #
    #  Normally an element record is created automatically every
    #  time an entity is created.
    #
    #  It's hard to create an entity without an element, but it can
    #  be done provided the entity has a real "active" field in the
    #  database.  Locations do.
    #
    element = Element.new
    assert_not element.valid?
    assert_equal "must exist", element.errors.messages[:entity][0]
    location = FactoryBot.create(:location, active: false)
    assert_not location.active?
    assert_nil location.element
    #
    #  Wouldn't normally do this.  We normally just set the active
    #  flag to true on the entity and then save the entity which
    #  will cause an element to be created to match.  What I'm doing
    #  her is just demonstrating that the element becomes valid if
    #  it is linked to an entity - even if the two don't really belong
    #  together.
    #
    element.entity = location
    assert element.valid?
  end

  test 'can have memberships attached' do
    exercise_has_many(
      attribute:       :memberships,
      child_type:      :membership,
      on_destroy:      :destroy)
  end

  test 'can have commitments attached' do
    exercise_has_many(
      attribute:       :commitments,
      child_type:      :commitment,
      on_destroy:      :destroy)
  end


  test 'can have proto_commitments attached' do
    exercise_has_many(
      attribute:       :proto_commitments,
      child_type:      :proto_commitment,
      on_destroy:      :destroy)
  end

  test 'can have requests attached' do
    exercise_has_many(
      attribute:       :requests,
      child_type:      :request,
      on_destroy:      :destroy) do |element, count|
      assert_equal count, element.requested_events.count

    end
  end

  test 'can have proto_requests attached' do
    exercise_has_many(
      attribute:       :proto_requests,
      child_type:      :proto_request,
      on_destroy:      :destroy)
  end

  test 'can be default group to exam cycles' do
    element = FactoryBot.create(:element)
    element.exam_cycles_as_default_group << ec1 = FactoryBot.create(:exam_cycle)
    element.exam_cycles_as_default_group << ec2 = FactoryBot.create(:exam_cycle)
    element.exam_cycles_as_default_group << ec3 = FactoryBot.create(:exam_cycle)
    assert_equal 3, element.exam_cycles_as_default_group.count
    element.destroy
    ec1.reload
    ec2.reload
    ec3.reload
    assert_nil ec1.default_group_element
    assert_nil ec2.default_group_element
    assert_nil ec3.default_group_element
  end

  test 'can be selector to exam cycles' do
    element = FactoryBot.create(:element)
    element.exam_cycles_as_selector << ec1 = FactoryBot.create(:exam_cycle)
    element.exam_cycles_as_selector << ec2 = FactoryBot.create(:exam_cycle)
    element.exam_cycles_as_selector << ec3 = FactoryBot.create(:exam_cycle)
    assert_equal 3, element.exam_cycles_as_selector.count
    element.destroy
    ec1.reload
    ec2.reload
    ec3.reload
    assert_nil ec1.selector_element
    assert_nil ec2.selector_element
    assert_nil ec3.selector_element
  end

  test 'can have concerns attached' do
    element = FactoryBot.create(:element)
    c1 = FactoryBot.create(:concern, element: element)
    c2 = FactoryBot.create(:concern, element: element)
    c3 = FactoryBot.create(:concern, element: element)
    assert_equal 3, element.concerns.count
    element.destroy
    assert_nil Concern.find_by(id: c1.id)
    assert_nil Concern.find_by(id: c2.id)
    assert_nil Concern.find_by(id: c3.id)
  end

  test 'do concerns another way' do
    exercise_has_many(
      attribute:       :concerns,
      child_type:      :concern,
      on_destroy:      :destroy)
  end

  #
  #  The next one is slightly odd in that FreeFinder records are not
  #  normally saved to the database (although they do have a database
  #  table).  Nothing to stop us doing it for testing purposes
  #  though.
  #
  test 'can have freefinders attached' do
    element = FactoryBot.create(:element)
    ff1 = FactoryBot.create(:freefinder, element: element)
    ff2 = FactoryBot.create(:freefinder, element: element)
    ff3 = FactoryBot.create(:freefinder, element: element)
    assert_equal 3, element.freefinders.count
    element.destroy
    assert_nil Freefinder.find_by(id: ff1.id)
    assert_nil Freefinder.find_by(id: ff2.id)
    assert_nil Freefinder.find_by(id: ff3.id)
  end

  test 'can be the prep element' do
    settings = Setting.first
    existing_prep_element = settings.prep_property_element
    element = FactoryBot.create(:element)
    settings.prep_property_element = element
    settings.save
    assert_not_nil element.prep_element_setting

    element.destroy
    settings.reload
    assert_nil settings.prep_property_element

    settings.prep_property_element = existing_prep_element
    settings.save
  end

  test 'can have journal_entries attached' do
    element = FactoryBot.create(:element)
    je1 = FactoryBot.create(:journal_entry, element: element)
    je2 = FactoryBot.create(:journal_entry, element: element)
    je3 = FactoryBot.create(:journal_entry, element: element)
    assert_equal 3, element.journal_entries.count
    element.destroy
    je1.reload
    je2.reload
    je3.reload
    assert_nil je1.element
    assert_nil je2.element
    assert_nil je3.element
  end

  test 'can be the organiser for events' do
    element = FactoryBot.create(:element)
    ev1 = FactoryBot.create(:event, organiser: element)
    ev2 = FactoryBot.create(:event, organiser: element)
    ev3 = FactoryBot.create(:event, organiser: element)
    assert_equal 3, element.organised_events.count
    element.destroy
    ev1.reload
    ev2.reload
    ev3.reload
    assert_nil ev1.organiser
    assert_nil ev2.organiser
    assert_nil ev3.organiser
  end

  test 'organiser another way' do
    exercise_has_many(
      attribute:       :organised_events,
      child_type:      :event,
      child_attribute: :organiser,
      on_destroy:      :nullify)
  end

  test "should have a viewable flag" do
    element = FactoryBot.create(:element)
    assert element.respond_to?(:viewable?)
  end

  test "locations_for_ical should return locations" do
    locations = @event.locations_for_ical(nil)
    assert_equal @all_locations.size, locations.size
    @all_locations.each do |l|
      assert locations.include?(l)
    end
  end

  test "locations_for_ical should observe weighting and spread" do
    locations = @event.locations_for_ical(20)
    assert_equal @heavy_locations.size, locations.size
    @heavy_locations.each do |l|
      assert locations.include?(l)
    end
    @light_locations.each do |l|
      assert_not locations.include?(l)
    end
  end

  test "locations_for_ical should observe subsidiarity" do
    @location2.subsidiary_to = @location1
    @location2.save
    @location4.subsidiary_to = @location1
    @location4.save
    locations = @event.locations_for_ical(nil)
    assert_equal 2, locations.size
  end

  test "subsidiarity check works even if non-continuous" do
    @location2.subsidiary_to = @location1
    @location2.save
    @location3.subsidiary_to = @location2
    @location3.save
    local_event = FactoryBot.create(:event,
                                    commitments_to: [@location1, @location3])
    locations = local_event.locations_for_ical(nil)
    assert_equal 1, locations.size
    assert locations.include?(@location1)
  end

  private

  def nested_attributes_for(*args)
    #
    #  This may need expanding at some point.
    #
    #  https://github.com/thoughtbot/factory_bot/issues/359
    #
    attributes = attributes_for(*args)
    klass = args.first.to_s.camelize.constantize

    klass.reflect_on_all_associations(:belongs_to).each do |r|
      association = FactoryBot.create(r.class_name.underscore)
      attributes["#{r.name}_id"] = association.id
      attributes["#{r.name}_type"] = association.class.name if r.options[:polymorphic]
    end

    attributes
  end

  def exercise_has_many(
    attribute:,
    child_type:,
    child_attribute: :element,
    on_destroy:
  )

    #
    #  First creating children specifying our element as being
    #  linked to them.
    #
    element = FactoryBot.create(:element)
    child1 = FactoryBot.create(child_type, { child_attribute => element })
    assert child1.valid?
    child2 = FactoryBot.create(child_type, { child_attribute => element })
    assert child2.valid?
    child3 = FactoryBot.create(child_type, { child_attribute => element })
    assert child3.valid?
    assert_equal 3, element.send(attribute).count
    if block_given?
      yield element, 3
    end
    element.destroy
    case on_destroy
    when :nullify
      child1.reload
      child2.reload
      child3.reload
      assert_nil child1.organiser
      assert_nil child2.organiser
      assert_nil child3.organiser
    when :destroy
      #
      #  Convert:
      #
      #  :able_baker -> "able_baker" -> "AbleBaker" -> AbleBaker
      #
      assert_nil child_type.to_s.camelize.constantize.find_by(id: child1.id)
      assert_nil child_type.to_s.camelize.constantize.find_by(id: child2.id)
      assert_nil child_type.to_s.camelize.constantize.find_by(id: child3.id)
    else
      raise "Error"
    end
    #
    #  Then using create method from our attribute.
    #
    element = FactoryBot.create(:element)
    #puts nested_attributes_for(child_type).inspect
    child1 = element.send(attribute).
                     create(nested_attributes_for(child_type).
                            except(child_attribute))
    #child1.valid?
    #puts child1.errors.inspect
    assert child1.valid?
    child2 = element.send(attribute).
                     create(nested_attributes_for(child_type).
                            except(child_attribute))
    assert child2.valid?
    child3 = element.send(attribute).
                     create(nested_attributes_for(child_type).
                            except(child_attribute))
    assert child3.valid?
    assert_equal 3, element.send(attribute).count
    if block_given?
      yield element, 3
    end
    element.destroy
    case on_destroy
    when :nullify
      assert_nil child1.organiser
      assert_nil child2.organiser
      assert_nil child3.organiser
    when :destroy
      assert child1.destroyed?
      assert child2.destroyed?
      assert child3.destroyed?
    else
      raise "Error"
    end
  end
end
