#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PupilTest < ActiveSupport::TestCase
  setup do
    @valid_params = {
      name: "Hi there - I'm a pupil"
    }
  end

  test "can create pupil" do
    pupil = Pupil.new(@valid_params)
    assert pupil.valid?
  end

  test "must have a name" do
    pupil = Pupil.new(@valid_params.except(:name))
    assert_not pupil.valid?
  end

end
