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

class TeachinggrouppersonaTest < ActiveSupport::TestCase
  setup do
    @subject = FactoryBot.create(:subject)
    @valid_params = {
      subject: @subject
    }
  end

  test "can create Teachinggrouppersona" do
    tgp = Teachinggrouppersona.new(@valid_params)
    assert tgp.valid?
  end

  test "subject is optional" do
    tgp = Teachinggrouppersona.new(@valid_params.except(:subject))
    assert tgp.valid?
  end

end
