require 'test_helper'

class EventAssemblerTest < ActiveSupport::TestCase

  setup do
    #
    #  This test assumes the existence of several EventCategories
    #  defined in the Fixtures - calendar, lesson, hidden.
    #
    #  Note that we need to create a matching staff member before
    #  we create the user, so that the user is marked as being
    #  staff, and thus "known".
    #
    @staff = FactoryBot.create(:staff, email: "staff@myschool.org.uk")
    @user = FactoryBot.create(:user,
                              email: "staff@myschool.org.uk",
                              show_owned: true)
    assert @user.known?
    assert @user.show_owned?
    @calendar_category = Eventcategory.find_by(name: "Calendar")
    @lesson_category   = Eventcategory.find_by(name: "Lesson")
    @hidden_category   = Eventcategory.find_by(name: "Hidden")
    @activity_category = Eventcategory.find_by(name: "Activity")
    @schoolwide_category = Eventcategory.find_by(name: "School wide")
    #
    #  Now we need an element by means of which to select events.
    #
    @my_property = FactoryBot.create(:property,
                                     name: "Event assembler test property")
    #
    #  And a concern with that element
    #
    @concern = FactoryBot.create(:concern,
                                 user: @user,
                                 element: @my_property.element,
                                 visible: true)
    #
    #  And some events involving that element
    #
    @just_before = FactoryBot.create(
      :event,
      body: "Just before",
      starts_at: Date.parse("2020-03-31"),
      ends_at: Date.parse("2020-04-01"),
      all_day: true,
      commitments_to: [@my_property],
      eventcategory: @lesson_category)
    @lesson_just_on = FactoryBot.create(
      :event,
      body: "Lesson just on",
      starts_at: Date.parse("2020-04-01"),
      ends_at: Date.parse("2020-04-02"),
      all_day: true,
      commitments_to: [@my_property],
      eventcategory: @lesson_category)
    @calendar_just_on = FactoryBot.create(
      :event,
      body: "Calendar just on",
      starts_at: Date.parse("2020-04-01"),
      ends_at: Date.parse("2020-04-02"),
      all_day: true,
      commitments_to: [@my_property],
      eventcategory: @calendar_category)
    @hidden_just_on = FactoryBot.create(
      :event,
      body: "Hidden just on",
      starts_at: Date.parse("2020-04-01"),
      ends_at: Date.parse("2020-04-02"),
      all_day: true,
      commitments_to: [@my_property],
      eventcategory: @hidden_category)
    @just_after = FactoryBot.create(
      :event,
      body: "Just after",
      starts_at: Date.parse("2020-04-03"),
      ends_at: Date.parse("2020-04-04"),
      all_day: true,
      commitments_to: [@my_property],
      eventcategory: @lesson_category)
    @owned_event = FactoryBot.create(
      :event,
      body: "Owned event",
      starts_at: Date.parse("2020-04-01"),
      ends_at: Date.parse("2020-04-02"),
      all_day: true,
      eventcategory: @activity_category,
      owner: @user)
    @school_wide_event = FactoryBot.create(
      :event,
      body: "School wide event",
      starts_at: Date.parse("2020-04-01"),
      ends_at: Date.parse("2020-04-02"),
      all_day: true,
      eventcategory: @schoolwide_category)

    #
    #  Stuff for our EventAssembler
    #
    @pseudo_session = Hash.new
    @basic_params = {
      start: "2020-04-01",
      end:   "2020-04-03",
      cid:   "#{@concern.id}"
    }
    @element_params = {
      start: "2020-04-01",
      end:   "2020-04-03",
      cid:   "UUE-#{@my_property.element.uuid}"
    }
    @just_mine_params = {
      start: "2020-04-01",
      end:   "2020-04-03",
      cid:   "0"
    }
    #
    #  For testing the inclusion options.  Just one event.
    #
    @room = FactoryBot.create(:location, name: "ABC")
    @teacher = FactoryBot.create(:staff, initials: "DEF")
    @inclusion_event = FactoryBot.create(
      :event,
      body: "With staff and room",
      #
      #  Completely different dates.
      #
      starts_at: Time.zone.parse("2021-04-01 11:30"),
      ends_at: Time.zone.parse("2021-04-01 12:15"),
      commitments_to: [@my_property, @room, @teacher],
      eventcategory: @lesson_category)
    @with_stuff_params = {
      start: "2021-04-01",
      end:   "2021-04-03",
      cid:   "#{@concern.id}"
    }

  end

  test "required categories exist" do
    assert_not_nil @calendar_category
    assert @calendar_category.visible
    assert_not_nil @lesson_category
    assert @lesson_category.visible
    assert_not_nil @hidden_category
    assert_not @hidden_category.visible
  end

  test "can create an EventAssembler" do
    ea = EventAssembler.new(@pseudo_session, @user, @basic_params)
    assert_not_nil ea
  end

  test "can fetch correct basic events" do
    found = EventAssembler.new(@pseudo_session, @user, @basic_params).call
    assert_equal 2, found.size
  end

  test "filtering switches off some events" do
    @user.suppressed_eventcategories << @calendar_category.id
    found = EventAssembler.new(@pseudo_session, @user, @basic_params).call
    assert_equal 1, found.size
  end

  test "can enable hidden events" do
    @user.extra_eventcategories << @hidden_category.id
    found = EventAssembler.new(@pseudo_session, @user, @basic_params).call
    assert_equal 3, found.size
  end

  test "can fetch by element id" do
    found = EventAssembler.new(@pseudo_session, @user, @element_params).call
    assert_equal 2, found.size
  end

  test "can fetch mine and schoolwide too" do
    @concern.visible = false
    @concern.save
    found = EventAssembler.new(@pseudo_session, @user, @just_mine_params).call
    assert_equal 6, found.size
  end

  test "can get staff included" do
    found = EventAssembler.new(@pseudo_session, @user, @with_stuff_params).call
    assert_equal 1, found.size
    assert_no_match /DEF/, found[0].title
    @concern.list_teachers = true
    @concern.save
    @user.reload
    found = EventAssembler.new(@pseudo_session, @user, @with_stuff_params).call
    assert_equal 1, found.size
    assert_match /DEF/, found[0].title
  end

  test "can get rooms included" do
    found = EventAssembler.new(@pseudo_session, @user, @with_stuff_params).call
    assert_equal 1, found.size
    assert_no_match /ABC/, found[0].title
    @concern.list_rooms = true
    @concern.save
    @user.reload
    found = EventAssembler.new(@pseudo_session, @user, @with_stuff_params).call
    assert_equal 1, found.size
    assert_match /ABC/, found[0].title
  end

  test "can get staff and rooms included" do
    found = EventAssembler.new(@pseudo_session, @user, @with_stuff_params).call
    assert_equal 1, found.size
    assert_no_match /ABC/, found[0].title
    assert_no_match /DEF/, found[0].title
    @concern.list_teachers = true
    @concern.list_rooms = true
    @concern.save
    @user.reload
    found = EventAssembler.new(@pseudo_session, @user, @with_stuff_params).call
    assert_equal 1, found.size
    assert_match /ABC/, found[0].title
    assert_match /DEF/, found[0].title
  end

end
