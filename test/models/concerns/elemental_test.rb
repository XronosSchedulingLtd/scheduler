require 'test_helper'

class ElementalTest < ActiveSupport::TestCase

  setup do
    @entities = {
      group:    Group,
      location: Location,
      property: Property,
      pupil:    Pupil,
      service:  Service,
      staff:    Staff,
      subject:  Subject
    }
  end

  test 'automatically gets an element' do
    @entities.keys.each do |key|
      entity = FactoryBot.create(key)
      assert entity.respond_to?(:element)
      assert_not_nil entity.element
    end
  end

  test 'saving updates element' do
    @entities.keys.each do |key|
      entity = FactoryBot.create(key)
      entity.name = "Banana fritter"
      entity.save
      entity.element.reload
      assert_equal entity.element_name, entity.element.name
    end
  end

  test 'must implement multicover' do
    @entities.keys.each do |key|
      entity = FactoryBot.create(key)
      assert entity.respond_to?(:multicover?), "Testing #{key}"
      assert entity.element.respond_to?(:multicover?)
      assert_equal entity.multicover?, entity.element.multicover?
    end

    staff = FactoryBot.create(:staff)
    assert_not staff.multicover
    assert_not staff.multicover?
    staff = FactoryBot.create(:staff, multicover: true)
    assert staff.multicover
    assert staff.multicover?
  end

  test 'must implement scan for clashes' do
    @entities.keys.each do |key|
      entity = FactoryBot.create(key)
      assert entity.respond_to?(:scan_for_clashes?), "Testing #{key}"
      assert entity.element.respond_to?(:scan_for_clashes?)
      assert_equal entity.scan_for_clashes?, entity.element.scan_for_clashes?
      #
      #  For now, only locations return true.
      #
      if key == :location
        assert entity.scan_for_clashes?
      else
        assert_not entity.scan_for_clashes?
      end
    end
  end

end
