#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class SubjectTest < ActiveSupport::TestCase
  setup do
    @valid_params = {
      name: "A subject"
    }
  end

  test "can create a subject" do
    subject = Subject.create(@valid_params)
    assert subject.valid?
  end

  test "must have a name" do
    subject = Subject.create(@valid_params.except(:name))
    assert_not subject.valid?
  end

  test "should acquire an element record" do
    subject = Subject.create(@valid_params)
    assert_not_nil subject.element
  end
end
