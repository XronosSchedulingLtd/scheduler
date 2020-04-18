#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PromptnoteTest < ActiveSupport::TestCase
  setup do
    @element = FactoryBot.create(:element)
    @valid_params = {
      element: @element
    }
  end

  test 'can create prompt note' do
    pn = Promptnote.new(@valid_params)
    assert pn.valid?
  end

  test 'must have an element' do
    pn = Promptnote.new(@valid_params.except(:element))
    assert_not pn.valid?
  end

  test 'can have notes' do
    pn = Promptnote.create(@valid_params)
    pn.notes << FactoryBot.create(:note)
    pn.notes << FactoryBot.create(:note)
    assert_equal 2, pn.notes.count
  end

  test 'deleting the promptnote orphans the notes' do
    pn = Promptnote.create(@valid_params)
    pn.notes << pn0 = FactoryBot.create(:note)
    pn.notes << pn1 = FactoryBot.create(:note)
    pn.destroy
    pn0.reload
    pn1.reload
    assert_nil pn0.promptnote
    assert_nil pn1.promptnote
  end

end
