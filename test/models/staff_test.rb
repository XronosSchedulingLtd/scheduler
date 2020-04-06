#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class StaffTest < ActiveSupport::TestCase

  setup do
    @entity_class = Staff
    @valid_params = {
      name: "Hello there - I'm staff",
      active: true
    }
  end

  include CommonEntityTests

  #
  #  The Staff model overrides the sorting method (<=>) and so needs
  #  its own separate sorting test.
  #

  test "staffs sort by surname forename" do
    staffs = []
    staffs << Staff.create(
      @valid_params.merge(
        {
          surname: "Wilson",
          forename: "Able"
        }
      )
    )
    staffs << Staff.create(
      @valid_params.merge(
        {
          surname: "Smith",
          forename: "Bert"
        }
      )
    )
    staffs << Staff.create(
      @valid_params.merge(
        {
          surname: "Smith",
          forename: "Able"
        }
      )
    )
    sorted = staffs.sort
    assert_equal staffs[0], sorted[2]
    assert_equal staffs[1], sorted[1]
    assert_equal staffs[2], sorted[0]
  end

end
