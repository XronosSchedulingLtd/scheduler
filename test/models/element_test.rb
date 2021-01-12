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

    @staff = FactoryBot.create(:staff)
    @pupil = FactoryBot.create(:pupil)
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
    exercise_has_many(
      attribute:       :exam_cycles_as_default_group,
      child_type:      :exam_cycle,
      child_attribute: :default_group_element,
      on_destroy:      :nullify)
  end

  test 'can be selector to exam cycles' do
    exercise_has_many(
      attribute:       :exam_cycles_as_selector,
      child_type:      :exam_cycle,
      child_attribute: :selector_element,
      on_destroy:      :nullify)
  end

  test 'can have concerns attached' do
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
    exercise_has_many(
      attribute:       :freefinders,
      child_type:      :freefinder,
      on_destroy:      :destroy)
  end

  test 'can be the prep element' do
    #
    #  This one can't use the standard exerciser because we can't
    #  create a new Setting element - there can be only one.
    #
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
    exercise_has_many(
      attribute:       :journal_entries,
      child_type:      :journal_entry,
      on_destroy:      :nullify)
  end

  test 'can be the organiser for events' do
    exercise_has_many(
      attribute:       :organised_events,
      child_type:      :event,
      child_attribute: :organiser,
      on_destroy:      :nullify)
  end

  test 'can be excluded from reports' do
    exercise_has_many(
      attribute:       :excluded_itemreports,
      child_type:      :itemreport,
      child_attribute: :excluded_element,
      on_destroy:      :nullify)
  end

  test 'can have a promptnote' do
    exercise_has_one(
      attribute:  :promptnote,
      child_type: :promptnote,
      on_destroy: :destroy)
  end

  test 'can have an owner' do
    user = FactoryBot.create(:user)
    element = FactoryBot.create(:element, owner: user)
    assert_equal user, element.owner
    assert_equal 1, user.elements.count
  end

  test 'can have a user form' do
    user_form = FactoryBot.create(:user_form)
    element = FactoryBot.create(:element, user_form: user_form)
    assert_equal user_form, element.user_form
    assert_equal 1, user_form.elements.count
  end

  test 'automatically assigned a uuid' do
    element = FactoryBot.create(:element)
    assert_not element.uuid.blank?
  end

  test 'cannot set uuid directly' do
    dummy_uuid = "Banana fritters"
    element = FactoryBot.create(:element)
    assert_not_equal dummy_uuid, element.uuid
    saved_uuid = element.uuid
    element.uuid = dummy_uuid
    assert_not_equal dummy_uuid, element.uuid
    assert_equal saved_uuid, element.uuid
  end

  test 'can give a preferred uuid at creation' do
    preferred_uuid = "Banana fritters"
    element = FactoryBot.create(:element, preferred_uuid: preferred_uuid)
    assert element.valid?
    assert_equal preferred_uuid, element.uuid
  end

  test 'cannot give preferred uuid after creation' do
    preferred_uuid = "Banana fritters"
    element = FactoryBot.create(:element)
    assert element.valid?
    element.preferred_uuid = preferred_uuid
    assert_not_equal preferred_uuid, element.uuid
  end

  test 'duplicate uuid at creation is overridden' do
    preferred_uuid = "Banana fritters"
    element1 = FactoryBot.create(:element, preferred_uuid: preferred_uuid)
    assert element1.valid?
    assert_equal preferred_uuid, element1.uuid
    element2 = FactoryBot.create(:element, preferred_uuid: preferred_uuid)
    assert element2.valid?
    assert_not_equal preferred_uuid, element2.uuid
  end

  test "should have a viewable flag" do
    element = FactoryBot.create(:element)
    assert element.respond_to?(:viewable?)
  end

  #
  #  Note that this is very similar to the explicit sorting test
  #  for *entities* (in sorting_test.rb) but here we're testing
  #  that you get the same behaviour with elements.
  #
  test 'can sort by entity type' do
    elements = Array.new
    Element::SORT_ORDER_HASH.each do |key, value|
      elements << FactoryBot.create(key.downcase.to_sym).element
    end
    assert_equal Element::SORT_ORDER_HASH.size, elements.size
    shuffled = elements.shuffle
    sorted = shuffled.sort
    elements.each_with_index do |element, i|
      assert_equal element, sorted[i]
    end
  end

  test 'personality hash gives correct results' do
    Element::PERSONALITY_HASH.each do |key, value|
      entity = FactoryBot.create(key.downcase.to_sym)
      assert_equal value, entity.a_person?
      assert_equal entity.a_person?, entity.element.a_person?
    end
  end

  test 'owning concern affects ownedness' do
    element = FactoryBot.create(:element)
    assert_not element.owned?
    concern1 = FactoryBot.create(:concern, element: element, owns: true)
    assert element.owned?
    concern2 = FactoryBot.create(:concern, element: element, owns: true)
    assert element.owned?
    #
    #  Check we can get a list of owners
    #
    owners = element.owners
    assert owners.include?(concern1.user)
    assert owners.include?(concern2.user)
    #
    #  And now get rid of them again.
    #
    concern1.destroy
    assert element.owned?
    owners = element.owners
    assert_not owners.include?(concern1.user)
    assert owners.include?(concern2.user)
    concern2.destroy
    assert_not element.owned?
  end

  test 'responds to can_lock' do
    element = FactoryBot.create(:element)
    assert element.respond_to?(:can_lock?)
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

  #
  #  Tests relating to membership of groups.
  #
  test 'can get memberships by their duration' do
    today = Date.today
    element = FactoryBot.create(:element)
    group1 = FactoryBot.create(:group, starts_on: today - 2.days)
    group2 = FactoryBot.create(:group)
    group3 = FactoryBot.create(:group)
    group4 = FactoryBot.create(:group)
    group5 = FactoryBot.create(:group)
    #
    #  Put our element in each of these groups for a different
    #  duration, taking today as day 0.
    #
    membership1 =
      FactoryBot.create(
        :membership,
        group: group1,
        element: element,
        starts_on: today - 2.days,
        ends_on: today + 7.days)
    membership2 =
      FactoryBot.create(
        :membership,
        group: group2,
        element: element,
        starts_on: today,
        ends_on: today + 2.days)
    membership3 =
      FactoryBot.create(
        :membership,
        group: group3,
        element: element,
        starts_on: today + 1.day,
        ends_on: today + 2.days)
    membership4 =
      FactoryBot.create(
        :membership,
        group: group4,
        element: element,
        starts_on: today + 3.days)
    membership5 =
      FactoryBot.create(
        :membership,
        group: group5,
        element: element,
        starts_on: today + 2.days,
        ends_on: today + 6.days)
    assert membership1.valid?
    assert membership2.valid?
    assert membership3.valid?
    assert membership4.valid?
    mbd = element.memberships_by_duration(
      start_date: today + 1.day,
      end_date: today + 8.days
    )
    #
    #  5 entries, in 4 batches.
    #
    assert_equal 5, mbd.count
    assert_equal 4, mbd.group_count
    #
    #  Dates should be:
    #
    #    Day 1 to day 2   - membership 2 and membership 3
    #    Day 1 to day 7   - membership 1
    #    Day 2 to day 6   - membership 5
    #    Day 3 to day 8   - membership 4
    #
    #  No two batches can have exactly the same dates (else they'd
    #  be the same batches) and they are sorted first by start date, then
    #  by end date.
    #
    mbd.grouped_mwds.each_with_index do |mwdb, index|
      assert mwdb.instance_of?(Membership::MWD_Set::MWD_Batch)
      #
      #  It makes sense to test these by index because putting them
      #  in order is part of the contract.
      #
      case index
      when 0
        assert_equal today + 1.day, mwdb.start_date
        assert_equal today + 2.days, mwdb.end_date
        assert_equal 2, mwdb.size
        assert mwdb.detect {|mwd| mwd.membership == membership2}
        assert mwdb.detect {|mwd| mwd.membership == membership3}
      when 1
        assert_equal today + 1.day, mwdb.start_date
        assert_equal today + 7.days, mwdb.end_date
        assert_equal 1, mwdb.size
        assert_equal membership1, mwdb[0].membership
      when 2
        assert_equal today + 2.days, mwdb.start_date
        assert_equal today + 6.days, mwdb.end_date
        assert_equal 1, mwdb.size
        assert_equal membership5, mwdb[0].membership
      when 3
        assert_equal today + 3.days, mwdb.start_date
        assert_equal today + 8.days, mwdb.end_date
        assert_equal 1, mwdb.size
        assert_equal membership4, mwdb[0].membership
      end
    end
  end

  test "can select just people" do
    people_elements = Element.person.to_a
    assert people_elements.include?(@staff.element)
    assert people_elements.include?(@pupil.element)
    assert_not people_elements.include?(@location1.element)
  end

  test "can select just staff" do
    staff_elements = Element.staff.to_a
    assert staff_elements.include?(@staff.element)
    assert_not staff_elements.include?(@pupil.element)
    assert_not staff_elements.include?(@location1.element)
  end

  test "can select just locations" do
    location_elements = Element.location.to_a
    assert_not location_elements.include?(@staff.element)
    assert_not location_elements.include?(@pupil.element)
    assert location_elements.include?(@location1.element)
    assert location_elements.include?(@location2.element)
    assert location_elements.include?(@location3.element)
    assert location_elements.include?(@location4.element)
  end

  test "property can be linked to ad hoc domain" do
    ahd = FactoryBot.create(:ad_hoc_domain)
    property = FactoryBot.create(:property)
    property.element.ad_hoc_domains_as_property << ahd
    ahd.reload
    assert_not_nil ahd.connected_property_element
    #
    #  And deleting the property should nullify the connection.
    #
    property.destroy
    ahd.reload
    assert_nil ahd.connected_property_element
  end

  test "subject can be linked to ad hoc domain" do
    ahd = FactoryBot.create(:ad_hoc_domain)
    subject = FactoryBot.create(:subject)
    subject.element.ad_hoc_domain_subjects.create(ad_hoc_domain: ahd)
    assert_equal 1, subject.element.ad_hoc_domain_subjects.count
    assert_equal 1, subject.element.ad_hoc_domains_as_subject.count
    #
    #  Deleting the subject destroys the connection
    #
    subject.destroy
    assert_equal 0, ahd.ad_hoc_domain_subjects.count
    assert_equal 0, ahd.subject_elements.count
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
      assert_nil child1.send(child_attribute)
      assert_nil child2.send(child_attribute)
      assert_nil child3.send(child_attribute)
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
    #  Then create, followed by link.
    #
    element = FactoryBot.create(:element)
    child1 = FactoryBot.build(child_type, { child_attribute => nil })
    child2 = FactoryBot.build(child_type, { child_attribute => nil })
    child3 = FactoryBot.build(child_type, { child_attribute => nil })
    element.send(attribute).send("<<", child1)
    element.send(attribute).send("<<", child2)
    element.send(attribute).send("<<", child3)
    assert child1.valid?
    assert child2.valid?
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
      assert_nil child1.send(child_attribute)
      assert_nil child2.send(child_attribute)
      assert_nil child3.send(child_attribute)
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
      child1.reload
      child2.reload
      child3.reload
      assert_nil child1.send(child_attribute)
      assert_nil child2.send(child_attribute)
      assert_nil child3.send(child_attribute)
    when :destroy
      assert child1.destroyed?
      assert child2.destroyed?
      assert child3.destroyed?
    else
      raise "Error"
    end
  end


  def exercise_has_one(
    attribute:,
    child_type:,
    child_attribute: :element,
    on_destroy:
  )

    #
    #  First creating child specifying our element as being
    #  linked to it.
    #
    element = FactoryBot.create(:element)
    child = FactoryBot.create(child_type, { child_attribute => element })
    assert child.valid?
    assert_not_nil element.send(attribute)
    if block_given?
      yield element
    end
    element.destroy
    case on_destroy
    when :nullify
      child.reload
      assert_nil child.send(child_attribute)
    when :destroy
      #
      #  Convert:
      #
      #  :able_baker -> "able_baker" -> "AbleBaker" -> AbleBaker
      #
      assert_nil child_type.to_s.camelize.constantize.find_by(id: child.id)
    else
      raise "Error"
    end
    #
    #  Then create it first and link it later.
    #
    element = FactoryBot.create(:element)
    #
    #  Note that we have to use build rather than create because we are
    #  explicitly excluding our linkage, and the child might not be
    #  valid without it.
    #
    child = FactoryBot.build(child_type, child_attribute => nil)
    #
    #  Might not be valid at this point.
    #
    element.send("#{attribute}=", child)
    assert_not_nil element.send(attribute)
    #
    #  Should by now be valid.
    #
    assert child.valid?
    if block_given?
      yield element
    end
    element.destroy
    case on_destroy
    when :nullify
      child.reload
      assert_nil child.send(child_attribute)
    when :destroy
      #
      #  Convert:
      #
      #  :able_baker -> "able_baker" -> "AbleBaker" -> AbleBaker
      #
      assert_nil child_type.to_s.camelize.constantize.find_by(id: child.id)
    else
      raise "Error"
    end

    #
    #  Then using create method from our own model's attribute.
    #
    element = FactoryBot.create(:element)
    child = element.send("create_#{attribute}".to_sym,
                         nested_attributes_for(child_type).
                           except(child_attribute))
    #child.valid?
    #puts child.errors.inspect
    assert child.valid?
    assert_not_nil element.send(attribute)
    if block_given?
      yield element
    end
    element.destroy
    case on_destroy
    when :nullify
      child.reload
      assert_nil child.send(child_attribute)
    when :destroy
      assert child.destroyed?
    else
      raise "Error"
    end
  end
end
