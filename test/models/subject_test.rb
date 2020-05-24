#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class SubjectTest < ActiveSupport::TestCase
  setup do
    @entity_class = Subject
    @valid_params = {
      name: "A subject"
    }
    @staff1 = FactoryBot.create(:staff)
    @staff2 = FactoryBot.create(:staff)
    @valid_teachinggroup_params = {
      chosen_persona: Teachinggrouppersona
    }
  end

  include CommonEntityTests

  test 'name need not be unique' do
    subject1 = Subject.create(@valid_params)
    assert subject1.valid?
    subject2 = Subject.create(@valid_params)
    assert subject2.valid?
  end

  test 'can select just current subjects' do
    #
    #  There are some created by fixtures.  Are these actually
    #  used anywhere?
    #
    existing_count = Subject.current.count
    subject1 = FactoryBot.create(:subject, current: true)
    subject2 = FactoryBot.create(:subject, current: false)
    subject3 = FactoryBot.create(:subject, current: true)
    subject4 = FactoryBot.create(:subject, current: false)
    assert_equal existing_count + 2, Subject.current.count
  end

  test 'no staff or teaching groups by default' do
    subject = Subject.create(@valid_params)
    assert_equal 0, subject.teachinggrouppersonae.count
    assert_equal 0, subject.staffs.count
  end

  test 'can add staff to subject' do
    subject = Subject.create(@valid_params)
    subject.staffs << @staff1
    subject.staffs << @staff2
    assert_equal 2, subject.staffs.count
    assert_equal 1, @staff1.subjects.count
    assert_equal 1, @staff2.subjects.count
  end

  test 'deleting the subject unlinks but does not delete the staff' do
    subject = Subject.create(@valid_params)
    subject.staffs << @staff1
    subject.staffs << @staff2
    subject.destroy
    assert_equal 0, @staff1.subjects.count
    assert_equal 0, @staff2.subjects.count
    assert_not @staff1.destroyed?
    assert_not @staff2.destroyed?
  end

  test 'can add teachinggroups to subject' do
    subject = Subject.create(@valid_params)
    tg1 = FactoryBot.create(
      :group,
      @valid_teachinggroup_params.merge(subject: subject))
    assert tg1.valid?
    tg2 = FactoryBot.create(
      :group,
      @valid_teachinggroup_params.merge(subject: subject))
    assert tg2.valid?
    assert_equal 2, subject.teachinggrouppersonae.count
    assert_equal subject, tg1.subject
    assert_equal subject, tg2.subject
    #
    #  And with the helper method.
    #
    assert_equal 2, subject.teachinggroups.count
    #
    #  And now delete our subject
    #
    subject.destroy
    tg1.reload
    tg2.reload
    assert_nil tg1.subject
    assert_nil tg2.subject
  end

  test 'linked events prevent destroying' do
    subject = Subject.create(@valid_params)
    assert subject.can_destroy?
    FactoryBot.create(:commitment, element: subject.element)
    assert_not subject.can_destroy?
  end

end
