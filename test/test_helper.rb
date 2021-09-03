ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include FactoryBot::Syntax::Methods

  def assert_no_errors
    assert_select '.field_with_errors', false, "There should be no errors"
  end

  def assert_errors
    assert_select '.field_with_errors'
  end

  #
  #  This method sets up some week letter events for us, for testing
  #  things which rely on them.  It works with 5 weeks, starting
  #  today.
  #
  #  Week A
  #  Week B
  #  Blank week - half term?
  #  Week A
  #  Week B
  #
  def create_week_letters
    base_date = Date.today
    @weekA1 =
      FactoryBot.create(
        :event,
        starts_at: base_date,
        ends_at: base_date + 7.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week A")
    @weekB1 =
      FactoryBot.create(
        :event,
        starts_at: base_date + 7.days,
        ends_at: base_date + 14.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week B")
    #
    #  1 week gap.  Half term?
    #
    @weekA2 =
      FactoryBot.create(
        :event,
        starts_at: base_date + 21.days,
        ends_at: base_date + 28.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week A")
    @weekB2 =
      FactoryBot.create(
        :event,
        starts_at: base_date + 28.days,
        ends_at: base_date + 35.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week B")
  end

  #
  #  This module contains tests which all entities (things which have
  #  elements) should pass.  Define @entity_class and @valid_params, then
  #  include it.
  #
  #  What goes here are tests to test things which the entity has by
  #  merit of it being an entity - a thing with an attached element.
  #
  module CommonEntityTests

    def test_can_create_entity
      entity = @entity_class.create(@valid_params)
      assert entity.valid?
    end

    def test_must_have_a_name
      entity = @entity_class.create(@valid_params.except(:name))
      assert_not entity.valid?
    end

    def test_must_have_a_non_blank_name
      entity = @entity_class.create(@valid_params.merge(name: ""))
      assert_not entity.valid?
    end

    def test_viewable_should_default_to_true
      entity = @entity_class.create(@valid_params)
      assert entity.element.viewable?
    end

    def test_can_create_with_viewable_false
      entity = @entity_class.create(@valid_params.merge({edit_viewable: false}))
      assert_not entity.element.viewable?
    end

    def test_string_0_should_work_as_false_too
      entity = @entity_class.create(@valid_params.merge({edit_viewable: "0"}))
      assert_not entity.element.viewable?
    end

    def test_string_1_should_work_as_true_too
      entity = @entity_class.create(@valid_params.merge({edit_viewable: "1"}))
      assert entity.element.viewable?
    end

    def test_entity_gets_element
      entity = @entity_class.create(@valid_params)
      assert entity.valid?
      assert entity.respond_to?(:element)
      entity.reload
      assert_not_nil entity.element
      assert_equal entity.element_name, entity.element.name
    end

    def test_inactive_entity_does_not_get_element
      sample = @entity_class.create(@valid_params)
      if sample.respond_to?(:active=)
        entity = @entity_class.create(@valid_params.merge({active: false}))
        assert entity.valid?
        assert_nil entity.element
      end
    end

    def test_entity_implements_preferred_uuid
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:preferred_uuid=)
      assert_not entity.respond_to?(:preferred_uuid)
    end

    def test_entity_implements_current
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:current)
    end

    def test_current_propagates_to_element
      #
      #  Some entities (property and subject) require the name to
      #  be unique.  Creating two like this will fail on the second
      #  if we don't amend the name.
      #
      entity = @entity_class.create(
        @valid_params.merge({
          name: "Number 1",
          current: true
        }))
      assert entity.element.current?
      entity = @entity_class.create(
        @valid_params.merge({
          name: "Number 2",
          current: false
        }))
      assert_not entity.element.current?
    end

    def test_implements_show_historic_panels
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:show_historic_panels?)
    end

    def test_implements_extra_panels
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:extra_panels?)
      if entity.extra_panels?
        assert entity.respond_to?(:extra_panels)
      end
    end

    def test_implements_add_directly
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:add_directly?)
    end

    def test_implements_display_name
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:display_name)
    end

    def test_implements_short_name
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:short_name)
    end

    def test_implements_more_type_info
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:more_type_info)
    end

    def test_implements_tabulate_name
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:tabulate_name)
    end

    def test_implements_csv_name
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:csv_name)
    end

    def test_implements_adjust_element_creation_hash
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:adjust_element_creation_hash)
    end

    def test_implements_general_partial
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:general_partial)
    end

    def test_implements_can_have_requests
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:can_have_requests?)
    end

    def test_implements_can_lock
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:can_lock?)
      assert_not entity.can_lock?
    end

    def test_implements_entitys_owner_id
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:entitys_owner_id)
    end

    def test_implements_description
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:description)
    end

    def test_implements_groups
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:groups)
    end

    def test_implements_commitments_on_and_during
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:commitments_on)
      assert entity.respond_to?(:commitments_during)
    end

    def test_implements_edit_preferred_colour
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:edit_preferred_colour)
      assert entity.respond_to?(:edit_preferred_colour=)
    end

    def test_should_not_have_preferred_colour_by_default
      entity = @entity_class.create(@valid_params)
      assert_nil entity.element.preferred_colour
    end

    def test_can_dictate_the_preferred_colour
      chosen_colour = "blue"
      entity = @entity_class.create(
        @valid_params.merge({edit_preferred_colour: chosen_colour}))
      assert_equal chosen_colour, entity.element.preferred_colour
    end

    def test_updating_entity_should_not_change_preferred_colour
      chosen_colour = "blue"
      entity = @entity_class.create(
        @valid_params.merge({edit_preferred_colour: chosen_colour}))
      assert_equal chosen_colour, entity.element.preferred_colour
      entity.name = "Banana"
      entity.save
      entity.reload
      assert_equal chosen_colour, entity.element.preferred_colour
    end

    def test_explicitly_changing_colour_should_change_element_colour
      chosen_colour = "blue"
      entity = @entity_class.create(
        @valid_params.merge({edit_preferred_colour: chosen_colour}))
      assert_equal chosen_colour, entity.element.preferred_colour
      entity.edit_preferred_colour = "red"
      entity.save
      entity.reload
      assert_equal "red", entity.element.preferred_colour
    end

    def test_can_remove_preferred_colour
      chosen_colour = "blue"
      entity = @entity_class.create(
        @valid_params.merge({edit_preferred_colour: chosen_colour}))
      assert_equal chosen_colour, entity.element.preferred_colour
      entity.edit_preferred_colour = ""
      entity.save
      entity.reload
      assert_nil entity.element.preferred_colour
    end

    def test_implements_edit_viewable
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:edit_viewable)
      assert entity.respond_to?(:edit_viewable=)
    end

    def test_implements_display_columns
      assert defined?(@entity_class::DISPLAY_COLUMNS)
    end

    def test_class_implements_a_person
      assert @entity_class.respond_to?(:a_person?)
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:a_person?)
    end

    def test_modifying_name_updates_element
      new_name = "Modified by common tests"
      entity = @entity_class.create(@valid_params)
      entity.reload
      assert_not_nil entity.element
      assert_not_equal new_name, entity.element.name
      entity.name = new_name
      entity.save
      entity.reload
      assert_equal entity.element_name, entity.element.name
    end

    def test_modifying_current_updates_element
      entity = @entity_class.create(@valid_params)
      entity.reload
      assert_not_nil entity.element
      assert_equal entity.current?, entity.element.current?
      entity.current = !entity.current?
      entity.save
      entity.reload
      assert_equal entity.current?, entity.element.current?
    end

    def test_modifying_active
      entity = @entity_class.create(@valid_params)
      assert entity.respond_to?(:active)
      assert entity.active
      #
      #  We can run the rest of this test only if the object 
      #  implements active=
      #
      if entity.respond_to?(:active=)
        element = entity.element
        assert_not_nil element
        entity.active = false
        entity.save
        entity.reload
        assert_nil entity.element
        assert element.destroyed?
        #
        #  And now make it active again.
        #
        entity.active = true
        entity.save
        entity.reload
        assert_not_nil entity.element
      end
    end

    def test_sort_by_name
      #
      #  Can only do this if the entity hasn't overridden the default
      #  one.
      #
      #  Is it then a meaningful test?  Not sure.
      #
      sample = @entity_class.create(@valid_params)
      assert sample.respond_to?(:<=>)
      if sample.method(:<=>).owner == Elemental
        entities = []
        entities << @entity_class.create(@valid_params.merge({name: "Baker"}))
        entities << @entity_class.create(@valid_params.merge({name: "Able"}))
        entities << @entity_class.create(@valid_params.merge({name: "Charlie"}))
        sorted = entities.sort
        assert_equal "Able",    sorted[0].name
        assert_equal "Baker",   sorted[1].name
        assert_equal "Charlie", sorted[2].name
      end
    end

    def test_gets_given_a_UUID
      entity = @entity_class.create(@valid_params)
      assert_not_nil entity.element.uuid
    end

    def test_can_dictate_the_UUID
      chosen_uuid = "Banana fritters"
      entity = @entity_class.create(@valid_params.merge({
        preferred_uuid: chosen_uuid}))
      assert_equal chosen_uuid, entity.element.uuid
    end

  end

end

class DummyFileInfo
  def original_filename
    "banana.png"
  end

  def read
    "Here is some data"
  end

  def size
    17
  end

end

