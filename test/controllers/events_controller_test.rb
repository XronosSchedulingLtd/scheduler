require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  setup do
    @event = FactoryBot.create(:event)
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, :admin, email: 'able@baker.com')
    session[:user_id] = user.id
    @format_dt = "%d/%m/%Y %H:%M"

    @all_day_start = Date.parse("2010-01-05")
    @all_day_end   = Date.parse("2010-01-10")
    @all_day_event = FactoryBot.create(
      :event,
      all_day: true,
      starts_at: @all_day_start,
      #
      #  Note that in the database the end date is stored as an exclusive
      #  date - that is, the day after the event ended.  When presented
      #  to the user, we show the date when it ends.
      #
      ends_at: @all_day_end + 1.day
    )
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create event" do
    assert_difference('Event.count') do
      post(
        :create,
        params: {
          event: {
            approximate: @event.approximate,
            body: @event.body,
            ends_at: @event.ends_at,
            eventcategory_id: @event.eventcategory_id,
            eventsource_id: @event.eventsource_id,
            non_existent: @event.non_existent,
            owner_id: @event.owner_id,
            private: @event.private,
            reference_id: @event.reference_id,
            reference_type: @event.reference_type,
            starts_at_text: @event.starts_at
          }
        }
      )
    end

    assert_redirected_to events_path
    assert_no_errors
  end

  test "should show event" do
    get :show, params: { id: @event }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @event }
    assert_response :success
    assert_select '#event_starts_at_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @event.starts_at.strftime(@format_dt), fields.first['value']
    end
    assert_select '#event_ends_at_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @event.ends_at.strftime(@format_dt), fields.first['value']
    end
  end

  test "should update event" do
    patch(
      :update,
      params: {
        id: @event,
        event: {
          approximate: @event.approximate,
          body: @event.body,
          ends_at: @event.ends_at,
          eventcategory_id: @event.eventcategory_id,
          eventsource_id: @event.eventsource_id,
          non_existent: @event.non_existent,
          owner_id: @event.owner_id,
          private: @event.private,
          reference_id: @event.reference_id,
          reference_type: @event.reference_type,
          starts_at_text: @event.starts_at
        }
      }
    )
    assert_redirected_to events_path
    assert_no_errors
  end

  test "should destroy event" do
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: @event }
    end

    assert_redirected_to events_path
  end

  #
  #  And now using the remote stuff used for dialogue boxes
  #

  test "should get edit dialogue" do
    get :edit, params: { id: @event }, xhr: true
    assert_response :success
    assert /^window.beginEditingEvent/ =~ response.body
    #
    #  Extract the encoded HTML.
    #
    splut = response.body.match(/(^window.beginEditingEvent\(\")(.*)(\"\);$)/)
    assert_not_nil splut
    fragment = Nokogiri::HTML.fragment(unescape_javascript(splut[2]))
    assert_select fragment, '#event_starts_at_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @event.starts_at.strftime(@format_dt), fields.first['value']
    end
    assert_select fragment, '#event_ends_at_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @event.ends_at.strftime(@format_dt), fields.first['value']
    end
  end

  test "should get edit dialogue for all day" do
    get :edit, params: { id: @all_day_event }, xhr: true
    assert_response :success
    assert /^window.beginEditingEvent/ =~ response.body
    #
    #  Extract the encoded HTML.
    #
    splut = response.body.match(/(^window.beginEditingEvent\(\")(.*)(\"\);$)/)
    assert_not_nil splut
    fragment = Nokogiri::HTML.fragment(unescape_javascript(splut[2]))
    assert_select fragment, '#event_starts_at_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @all_day_start.to_s(:dmy), fields.first['value']
    end
    assert_select fragment, '#event_ends_at_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @all_day_end.to_s(:dmy), fields.first['value']
    end
  end

  private

  def unescape_javascript(text)
    text.gsub('\/', '/').gsub('\n', "\n").gsub('\"', '"').gsub("\\'", "'")
  end

end
