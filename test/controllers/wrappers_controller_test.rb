require 'test_helper'

class WrappersControllerTest < ActionController::TestCase
  setup do
    @ordinary_user =
      FactoryBot.create(:user,
                        :editor,
                        user_profile: UserProfile.staff_profile)
    @owning_user =
      FactoryBot.create(:user,
                        :editor,
                        user_profile: UserProfile.staff_profile)
    @admin_user =
      FactoryBot.create(:user,
                        :editor,
                        :admin,
                        user_profile: UserProfile.staff_profile)
    @existing_event = FactoryBot.create(:event, owner: @owning_user)
    #
    #  The event will have been created with a start time specified
    #  to the millisecond, however when saved to the database it
    #  is saved to an accuracy of a second.
    #
    #  Re-load it now so that subsequent comparisons come out the same.
    #
    @existing_event.reload
  end

  test 'unauthorized attempt refused' do
    session[:user_id] = @ordinary_user.id
    assert_not @ordinary_user.can_subedit?(@existing_event)
    xhr :get, :new, event_id: @existing_event.id
    assert_response :forbidden
  end

  test 'authorized attempt gets form' do
    session[:user_id] = @owning_user.id
    assert @owning_user.can_subedit?(@existing_event)
    xhr :get, :new, event_id: @existing_event.id
    assert_response :success
    #
    #  Not going to check the whole of the form, but make sure it
    #  starts by invoking the right JavaScript function.
    #
    assert /^window.beginWrapping/ =~ response.body
  end

  test 'can have just a before wrapper' do
    session[:user_id] = @owning_user.id
    assert_difference 'Event.count', 1 do
      xhr :post,
          :create,
          event_id: @existing_event.id,
          event_wrapper: {
            single_wrapper: '0',
            wrap_before: '1',
            wrap_after: '0',
            before_duration: '25',
            before_title: 'Able stable'
          }
      assert_response :success
    end
    new_event = Event.last
    assert_equal @existing_event.starts_at, new_event.ends_at
    assert_equal @existing_event.starts_at - 25.minutes, new_event.starts_at
    assert_equal 'Able stable', new_event.body
  end

  test 'can have just an after wrapper' do
    session[:user_id] = @owning_user.id
    assert_difference 'Event.count', 1 do
      xhr :post,
          :create,
          event_id: @existing_event.id,
          event_wrapper: {
            single_wrapper: '0',
            wrap_before: '0',
            wrap_after: '1',
            after_duration: '38',
            after_title: 'Boogle flip'
          }
      assert_response :success
    end
    new_event = Event.last
    assert_equal @existing_event.ends_at, new_event.starts_at
    assert_equal @existing_event.ends_at + 38.minutes, new_event.ends_at
    assert_equal 'Boogle flip', new_event.body
  end

  test 'can have both wrappers' do
    session[:user_id] = @owning_user.id
    assert_difference 'Event.count', 2 do
      xhr :post,
          :create,
          event_id: @existing_event.id,
          event_wrapper: {
            single_wrapper: '0',
            wrap_before: '1',
            wrap_after: '1'
          }
      assert_response :success
    end
  end

  test 'can have a single wrapping event' do
    session[:user_id] = @owning_user.id
    assert_difference 'Event.count', 1 do
      xhr :post,
          :create,
          event_id: @existing_event.id,
          event_wrapper: {
            single_wrapper: '1',
            wrap_before: '1',
            wrap_after: '1',
            single_before_duration: '84',
            single_after_duration: '99',
            single_title: 'That is it'
          }
      assert_response :success
    end
    new_event = Event.last
    assert_equal @existing_event.starts_at - 84.minutes, new_event.starts_at
    assert_equal @existing_event.ends_at + 99.minutes, new_event.ends_at
    assert_equal 'That is it', new_event.body
  end

end
