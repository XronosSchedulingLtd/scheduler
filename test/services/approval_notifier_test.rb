require 'test_helper'

class ApprovalNotifierTest < ActiveSupport::TestCase

  setup do
    #
    #  Need an owned resource
    #
    @property = FactoryBot.create(:property)
    @allocating_user = FactoryBot.create(:user)
    @concern = FactoryBot.create(:concern,
                                 user: @allocating_user,
                                 element: @property.element,
                                 owns: true)
    #
    #  With a future commitment
    #
    @event = FactoryBot.create(
      :event,
      starts_at: Date.today + 1.day,
      ends_at:   Date.today + 2.days,
      all_day:   true)
    @commitment = FactoryBot.create(
      :commitment,
      event: @event,
      element: @property.element,
      status: :requested)
    #
    #  And a partially complete form.
    #
    @user_form = FactoryBot.create(:user_form,
                                   elements: [@property.element])
    @ufr = FactoryBot.create(:user_form_response,
                              user_form: @user_form,
                              parent: @commitment,
                              status: :partial)
  end

  test "can scan elements" do
    ApprovalNotifier.new.scan_elements
  end
end
