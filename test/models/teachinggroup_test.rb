#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class TeachinggroupTest < ActiveSupport::TestCase
  setup do
    @subject = FactoryBot.create(:subject)
    @era = FactoryBot.create(:era)
    @valid_params = {
      name:      'A teaching group',
      era:       @era,
      starts_on: @era.starts_on,
      subject:   @subject
    }
  end

  test "can create a teaching group in one go" do
    tg = Teachinggroup.create!(@valid_params)
    assert tg.valid?
    assert tg.respond_to?(:subject)
    assert_equal @subject, tg.subject
  end

  test "can create a teaching group bit by bit" do
    tg = Teachinggroup.new
    assert tg.respond_to?(:subject)
    assert_not tg.valid?
    tg.update_attributes(@valid_params)
    assert tg.valid?
    assert tg.save
  end

end
