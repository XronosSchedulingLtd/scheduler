require 'test_helper'

class EventCollectionsControllerTest < ActionController::TestCase
  setup do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, :admin, email: 'able@baker.com')
    session[:user_id] = user.id
    @event_collection = FactoryBot.create(:event_collection)
    @collected_event = FactoryBot.create(
      :event,
      event_collection: @event_collection,
      owner: user)
    @bare_event = FactoryBot.create(
      :event,
      owner: user)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should show event collection" do
    get :show, params: {id: @event_collection}
    assert_response :success
  end

  test "should get new" do
    get :new, params: {event_id: @bare_event}, xhr: true
    assert_response :success
    assert /^window.beginWrapping/ =~ response.body
    #
    #  Extract the encoded HTML.
    #
    splut = response.body.match(/(^window.beginWrapping\(\")(.*)(\"\);$)/)
    assert_not_nil splut
    fragment = Nokogiri::HTML.fragment(unescape_javascript(splut[2]))
    assert_select fragment, '#event_collection_repetition_start_date' do |fields|
      assert_equal 1, fields.count
      assert_equal Date.today.to_s, fields.first['value']
    end
    assert_select fragment, '#event_collection_repetition_end_date' do |fields|
      assert_equal 1, fields.count
      assert_equal (Date.today + 3.months).to_s, fields.first['value']
    end
  end

  test "should create event collection" do
    start_date = @bare_event.starts_at.to_date
    assert_difference('EventCollection.count') do
      post(
        :create,
        params: {
          event_id: @bare_event,
          event_collection: {
            repetition_start_date: start_date.to_s,
            repetition_end_date:   (start_date + 3.months).to_s,
            days_of_week: [1,2,3,4,5],
            weeks: ["A", "B", " "],
            era_id:  Setting.current_era
          }
        },
        xhr: true
      )
    end
    assert /^window.closeModal/ =~ response.body
  end

  #
  #  This is the one error produced by the controller itself, rather
  #  than by validation in the model.  Hence test here.
  #
  test "no instances produces error" do
    start_date = @bare_event.starts_at.to_date
    assert_difference('EventCollection.count', 0) do
      post(
        :create,
        params: {
          event_id: @bare_event,
          event_collection: {
            repetition_start_date: start_date.to_s,
            repetition_end_date:   (start_date + 3.months).to_s,
            days_of_week: [],
            weeks: ["A", "B", " "],
            era_id:  Setting.current_era
          }
        },
        xhr: true
      )
    end
    assert /^window.beginWrapping/ =~ response.body
    splut = response.body.match(/(^window.beginWrapping\(\")(.*)(\"\);$)/)
    assert_not_nil splut
    fragment = Nokogiri::HTML.fragment(unescape_javascript(splut[2]))
    assert_select fragment, '#error_explanation' do |fields|
      assert_select fields, 'li', /no events at all/
    end
  end


  test "should get edit" do
    get :edit, params: { event_id: @collected_event, id: @event_collection }, xhr: true
    assert_response :success
    assert /^window.beginWrapping/ =~ response.body
    splut = response.body.match(/(^window.beginWrapping\(\")(.*)(\"\);$)/)
    assert_not_nil splut
    fragment = Nokogiri::HTML.fragment(unescape_javascript(splut[2]))
    assert_select fragment, '#event_collection_repetition_start_date' do |fields|
      assert_equal 1, fields.count
      assert_equal @event_collection.repetition_start_date.to_s, fields.first['value']
    end
    assert_select fragment, '#event_collection_repetition_end_date' do |fields|
      assert_equal 1, fields.count
      assert_equal @event_collection.repetition_end_date.to_s, fields.first['value']
    end
  end


  test "should update event" do
    patch(
      :update,
      params: {
        event_id: @collected_event,
        id: @event_collection,
        event_collection: {
          days_of_week: [1,2],
          weeks: ["A", "B", " "]
        }
      },
      xhr: true
    )
    assert_response :success
    assert /^window.closeModal/ =~ response.body
  end


  test "should destroy event collection" do
    assert_difference('EventCollection.count', -1) do
      delete(
        :destroy,
        params: {
          event_id: @collected_event,
          id: @event_collection
        }, xhr: true
      )
    end
    assert_response :success
  end

  private

  def unescape_javascript(text)
    text.gsub('\/', '/').gsub('\n', "\n").gsub('\"', '"').gsub("\\'", "'")
  end

end
