#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

#
#  Note that a Tutorgrouppersona does not normally exist in isolation.
#  This test module does only very basic testing of its validation.
#

class TutorgrouppersonaTest < ActiveSupport::TestCase
  setup do
    @staff = FactoryBot.create(:staff)
    @valid_params = {
      staff: @staff
    }
  end

  test "can create Tutorgrouppersona" do
    tgp = Tutorgrouppersona.new(@valid_params)
    assert tgp.valid?
  end

  test "must have a staff member" do
    tgp = Tutorgrouppersona.new(@valid_params.except(:staff))
    assert_not tgp.valid?
  end

end
