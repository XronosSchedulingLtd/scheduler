require 'test_helper'

class ApiTest < ActionDispatch::IntegrationTest
  setup do
    @api_user =
      FactoryBot.create(
        :user, :api,
        user_profile: UserProfile.staff_profile,
        email: "api_user@myschool.org.uk")
    @other_api_user =
      FactoryBot.create(
        :user, :api,
        user_profile: UserProfile.staff_profile,
        email: "other_api_user@myschool.org.uk")
    @api_user_no_edit =
      FactoryBot.create(
        :user, :api, :not_editor,
        user_profile: UserProfile.staff_profile,
        email: "api_user_no_edit@myschool.org.uk")
    @privileged_api_user =
      FactoryBot.create(
        :user, :api, :privileged,
        user_profile: UserProfile.staff_profile,
        email: "privileged_api_user@myschool.org.uk")
    @api_user_with_su =
      FactoryBot.create(
        :user, :api, :su,
        user_profile: UserProfile.staff_profile,
        email: "api_user_with_su@myschool.org.uk")
    @admin_user =
      FactoryBot.create(
        :user, :admin,
        user_profile: UserProfile.staff_profile,
        email: "admin_user@myschool.org.uk")
    @ordinary_user =
      FactoryBot.create(
        :user,
        user_profile: UserProfile.staff_profile,
        email: "ordinary_user@myschool.org.uk")
    @staff1 = FactoryBot.create(
      :staff, {name: "Able Baker Charlie", initials: "ABC"})
    @pupil1 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Maximus")
    @pupil2 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Major")
    @pupil3 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Minor")
    @pupil4 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Minimus")
    @group1 = FactoryBot.create(:group)
    @location1 = FactoryBot.create(:location)
    @property1 = FactoryBot.create(:property)
    @service1 = FactoryBot.create(:service)
    @subject1 = FactoryBot.create(:subject)
    @resourcegroup = FactoryBot.create(:resourcegroup)
    #
    #  You can't create events unless this event source exists.
    #
    @eventsource = FactoryBot.create(:eventsource, name: 'API')
    @eventcategory = FactoryBot.create(:eventcategory, name: 'Test API events')
    @privileged_eventcategory = FactoryBot.create(:eventcategory,
                                                  name: 'Privileged category',
                                                  privileged: true)
    @event_start_time = Time.zone.now
    @event_end_time = Time.zone.now + 1.hour
    @valid_event_params = {
      body:           'My test event',
      starts_at_text: @event_start_time.strftime("%d/%m/%Y %H:%M"),
      ends_at_text:   @event_end_time.strftime("%d/%m/%Y %H:%M"),
      eventcategory_id: @eventcategory.id
    }
    @elements_to_add = [
      @staff1.element,
      @pupil1.element,
      @location1.element,
      @resourcegroup.element
    ]
    @element_ids_to_add = @elements_to_add.collect {|e| e.id}

    @existing_event = FactoryBot.create(:event,
                                        owner: @api_user,
                                        organiser: @staff1.element)

    @existing_note = FactoryBot.create(:note,
                                       parent: @existing_event,
                                       owner: @api_user,
                                       contents: "A note for an existing event")

    @api_paths = PublicApi::Engine.routes.url_helpers
  end

  #
  #  Basic login and logout
  #
  test "login requests must be json" do
    get @api_paths.login_path(uid: @api_user.uuid)
    assert_redirected_to "/"
  end

  test "random uid does not log in" do
    get @api_paths.login_path(uid: 'ablebakercharlie'), params: { format: :json }
    assert_response 401         # Unauthorized
  end

  test "ordinary user cannot log in through api" do
    get @api_paths.login_path(uid: @ordinary_user.uuid), params: { format: :json }
    assert_response 401         # Unauthorized
  end

  test "api user can log in through api" do
    get @api_paths.login_path(uid: @api_user.uuid), params: { format: :json }
    assert_response :success
  end

  test "logout requests must be json" do
    get @api_paths.logout_path
    assert_redirected_to "/"
  end

  test "logout always succeeds" do
    get @api_paths.logout_path, params: { format: :json }
    assert_response :success
  end

  #
  #  Login required for other actions
  #  After logout, actions no longer available.
  #
  test "authentication required" do
    #
    #  Initially can't issue an arbitrary request.
    #
    get @api_paths.elements_path, params: { format: :json }
    assert_response 401         # Unauthorized
    #
    #  Then login and we can.
    #
    do_valid_login
    get @api_paths.elements_path, params: { format: :json }
    assert_response :success
    #
    #  Then logout and we can't again.
    #
    do_logout
    get @api_paths.elements_path, params: { format: :json }
    assert_response 401         # Unauthorized
  end

  #
  #  Now test the elements controller.
  #
  test "index with no params gets empty response" do
    do_valid_login
    get @api_paths.elements_path, params: { format: :json }
    assert_response :success
    data = unpack_response(response, 'OK')
    elements = data['elements']
    #
    #  elements should be an empty array.
    #
    assert_instance_of Array, elements
    assert_empty elements
  end

  test "search for non-existent element returns appropriate error" do
    do_valid_login
    get @api_paths.elements_path(name: 'Banana fritter'), params: { format: :json }
    assert_response :missing
  end

  test "search for existing element finds it" do
    do_valid_login
    get @api_paths.elements_path(name: 'ABC - Able Baker Charlie'),
        params: { format: :json }
    assert_response :success
    data = unpack_response(response, 'OK')
    elements = data['elements']
    assert_instance_of Array, elements
    assert_equal 1, elements.size
    check_element_summary(elements[0])
  end

  test "fuzzy search for non-existent element returns appropriate error" do
    do_valid_login
    get @api_paths.elements_path(namelike: 'Banana fritter'), params: { format: :json }
    assert_response :missing
  end

  test "fuzzy search finds existing elements" do
    do_valid_login
    get @api_paths.elements_path(namelike: 'Fotheringay'),
        params: { format: :json }
    assert_response :success
    data = unpack_response(response, 'OK')
    elements = data['elements']
    assert_instance_of Array, elements
    assert_equal 4, elements.size
    elements.each do |element|
      check_element_summary(element)
    end
  end

  test 'limit of 100 on how many elements returned' do
    105.times do |i|
      FactoryBot.create(:pupil, name: "Pupil #{i}")
    end
    do_valid_login
    get @api_paths.elements_path(namelike: 'Pupil'),
        params: { format: :json }
    assert_response :success
    data = unpack_response(response, 'OK')
    elements = data['elements']
    assert_instance_of Array, elements
    assert_equal 100, elements.size
    elements.each do |element|
      check_element_summary(element)
    end
  end

  test "element show with invalid id returns appropriate error" do
    do_valid_login
    get @api_paths.element_path(id: 999), params: { format: :json }
    assert_response :missing
    unpack_response(response, 'Not found')
  end

  test "element show succeeds for valid staff element" do
    do_valid_login
    do_show_element(@staff1.element)
  end

  test "element show succeeds for valid pupil element" do
    do_valid_login
    do_show_element(@pupil1.element)
  end

  test "element show succeeds for valid group element" do
    do_valid_login
    do_show_element(@group1.element)
  end

  test "element show succeeds for valid location element" do
    do_valid_login
    do_show_element(@location1.element)
  end

  test "element show succeeds for valid property element" do
    do_valid_login
    do_show_element(@property1.element)
  end

  test "element show succeeds for valid service element" do
    do_valid_login
    do_show_element(@service1.element)
  end

  test "element show succeeds for valid subject element" do
    do_valid_login
    do_show_element(@subject1.element)
  end

  #
  #  And now the events controller
  #
  test "event create without params fails" do
    do_valid_login
    post @api_paths.events_path, params: { format: :json }
    assert_response 400         # Bad request
  end

  test "event create with valid params succeeds" do
    do_valid_login
    post @api_paths.events_path(event: @valid_event_params), params: { format: :json }
    assert_response 201         # Created
  end

  test "can specify an organiser when creating an event" do
    do_valid_login
    post @api_paths.events_path(
      event: @valid_event_params.merge({
        organiser_id: @staff1.element.id
      })), params: { format: :json }
    assert_response 201         # Created
    #
    #  And check that the organiser did indeed get set.  This requires
    #  us to query the new event.
    #
    response_data = unpack_response(response, 'Created')
    #
    #  Check for failures - there should be none.
    #
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_empty failures
    #
    #  Now query the event to see who the organiser is.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    event_id = event['id']
    get @api_paths.event_path(event_id), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    event = response_data['event']
    assert_instance_of Hash, event
    organiser = event['organiser']
    assert_not_nil organiser
    assert_equal @staff1.element.id, organiser['id']
  end

  test "unauthorized user can't create event" do
    do_valid_login(@api_user_no_edit)
    post @api_paths.events_path(event: @valid_event_params), params: { format: :json }
    assert_response 403         # Forbidden
  end

  test "ordinary api user can't use privileged category" do
    do_valid_login
    post @api_paths.events_path(
      event: @valid_event_params.merge({
        eventcategory_id: @privileged_eventcategory.id})), params: { format: :json }
    assert_response 403         # Forbidden
  end

  test "but a privileged user can" do
    do_valid_login(@privileged_api_user)
    post @api_paths.events_path(
      event: @valid_event_params.merge({
        eventcategory_id: @privileged_eventcategory.id})), params: { format: :json }
    assert_response 201         # Created
  end

  test "can add elements whilst creating" do
    do_valid_login
    post @api_paths.events_path(
      event: @valid_event_params,
      elements: @element_ids_to_add
    ), params: { format: :json }
    assert_response 201         # Created
    response_data = unpack_response(response, 'Created')
    #
    #  Check for failures - there should be none.
    #
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_empty failures
    #
    #  And check the event has the right fields, plus the right number
    #  of commitments and requests.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    assert_equal @valid_event_params[:body], event['body']
    compare_times @valid_event_params[:starts_at_text], event['starts_at']
    compare_times @valid_event_params[:ends_at_text], event['ends_at']
    assert_not event['all_day']
    #
    #  How many should be commitments and how many requests?
    #
    for_requests, for_commitments =
      @elements_to_add.partition {|e| e.can_have_requests?}
    assert_equal for_requests.size,
      event['requests'].size
    assert_equal for_commitments.size,
      event['commitments'].size
  end

  test 'two entries for same requestable item result in one request' do
    do_valid_login
    post @api_paths.events_path(
      event: @valid_event_params,
      elements: [@resourcegroup.element.id, @resourcegroup.element.id]
    ), params: { format: :json }
    assert_response 201         # Created
    response_data = unpack_response(response, 'Created')
    #
    #  Check for failures - there should be none.
    #
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_empty failures
    #
    #  Should have one request, with a quantity of 2.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    requests = event['requests']
    assert_equal 1, requests.size
    assert_equal 2, requests[0]['quantity']
  end

  test 'two entries for same ordinary item result in a failure' do
    do_valid_login
    post @api_paths.events_path(
      event: @valid_event_params,
      elements: [@staff1.element.id, @staff1.element.id]
    ), params: { format: :json }
    assert_response 201         # Created
    response_data = unpack_response(response, 'Created')
    #
    #  Check for failures - there should be one.
    #
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_equal 1, failures.size
    #
    #  Should have just one commitment.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    commitments = event['commitments']
    assert_equal 1, commitments.size
  end

  test 'can add elements after creating event' do
    do_valid_login
    post @api_paths.events_path(
      event: @valid_event_params
    ), params: { format: :json }
    assert_response 201         # Created
    response_data = unpack_response(response, 'Created')
    #
    #  We have our event - now add to it.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    event_id = event['id']

    post @api_paths.add_event_path(event_id,
                                   elements: @element_ids_to_add),
                                   params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    #
    #  Check for failures - there should be none.
    #
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_empty failures
    #
    #  And check the event has the right number
    #  of commitments and requests.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    #
    #  How many should be commitments and how many requests?
    #
    for_requests, for_commitments =
      @elements_to_add.partition {|e| e.can_have_requests?}
    assert_equal for_requests.size,
      event['requests'].size
    assert_equal for_commitments.size,
      event['commitments'].size
  end

  test 'can query an existing event' do
    do_valid_login
    get @api_paths.event_path(@existing_event), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    event = response_data['event']
    assert_instance_of Hash, event
  end

  test 'querying non-existent event returns correct status' do
    do_valid_login
    get @api_paths.event_path(999), params: { format: :json }
    assert_response :missing
    response_data = unpack_response(response, 'Not found')
  end

  test 'event query returns both commitments and requests' do
    do_valid_login
    #
    #  Start by adding some stuff to our existing event.
    #
    post @api_paths.add_event_path(@existing_event.id,
                                   elements: @element_ids_to_add),
                                   params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    #
    #  Check for failures - there should be none.
    #
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_empty failures
    #
    #  Now query it.
    #
    get @api_paths.event_path(@existing_event), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    #
    #
    #  And check the event has the right number
    #  of commitments and requests.
    #
    event = response_data['event']
    assert_instance_of Hash, event
    #
    #  How many should be commitments and how many requests?
    #
    for_requests, for_commitments =
      @elements_to_add.partition {|e| e.can_have_requests?}
    assert_equal for_requests.size,
      event['requests'].size
    assert_equal for_commitments.size,
      event['commitments'].size
  end

  test 'event query should return extra details' do
    do_valid_login
    get @api_paths.event_path(@existing_event), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    event = response_data['event']
    assert_instance_of Hash, event
    assert_not_nil event['starts_at']
    assert_not_nil event['ends_at']
    assert_not_nil event['all_day']
    #
    #  Not all events have an owner or organiser, so all we can
    #  check in general is that the field exists.  However,
    #  our own constructed event does have both of these specified.
    #
    assert_not_nil event['organiser']
    assert_not_nil event['owner']
    assert_not_nil event['requests']
    assert_not_nil event['commitments']
  end

  #
  #  The requests controller.  Should be able to:
  #
  #  1. Get a listing of requests for an element for a range of dates
  #  2. Delete a specific request (subject to access permissions)
  #

  test 'should be able to get listing of requests for an element' do
    do_valid_login
    event1 = generate_event_on(Date.today,          @resourcegroup.element)
    event2 = generate_event_on(Date.today + 1.day,  @resourcegroup.element)
    event3 = generate_event_on(Date.today + 2.days, @resourcegroup.element)
    #
    #  Try for all 3 days.
    #
    get @api_paths.element_requests_path(
      @resourcegroup.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    requests = response_data['requests']
    assert_instance_of Array, requests
    assert_equal 3, requests.size
    #
    #  Just 2 days should give only 2 of them.
    #
    get @api_paths.element_requests_path(
      @resourcegroup.element,
      start_date: (Date.today + 1.day).strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    requests = response_data['requests']
    assert_instance_of Array, requests
    assert_equal 2, requests.size
    #
    #  And no date at all should give us just 1 - today's.
    #
    get @api_paths.element_requests_path(
      @resourcegroup.element
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    requests = response_data['requests']
    assert_instance_of Array, requests
    assert_equal 1, requests.size
  end

  test 'should be able to delete a request' do
    do_valid_login
    event1 = generate_event_on(Date.today,          @resourcegroup.element)
    event2 = generate_event_on(Date.today + 1.day,  @resourcegroup.element)
    event3 = generate_event_on(Date.today + 2.days, @resourcegroup.element)
    #
    #  Try for all 3 days.
    #
    get @api_paths.element_requests_path(
      @resourcegroup.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    requests = response_data['requests']
    assert_instance_of Array, requests
    assert_equal 3, requests.size
    #
    #  Now delete the middle one.
    #
    target_id = event2['requests'][0]['id']

    delete @api_paths.request_path(target_id), params: { format: :json }
    assert_response :success

    #
    #  And there should be only 2 left.
    #
    get @api_paths.element_requests_path(
      @resourcegroup.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    requests = response_data['requests']
    assert_instance_of Array, requests
    assert_equal 2, requests.size
  end

  #
  #  And similarly for the commitments controller.
  #
  #  1. Get a listing of commitments for an element for a range of dates
  #  2. Delete a specific commitment (subject to access permissions)
  #

  test 'should be able to get listing of commitments for an element' do
    do_valid_login
    event1 = generate_event_on(Date.today,          @staff1.element)
    event2 = generate_event_on(Date.today + 1.day,  @staff1.element)
    event3 = generate_event_on(Date.today + 2.days, @staff1.element)
    #
    #  Try for all 3 days.
    #
    get @api_paths.element_commitments_path(
      @staff1.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 3, commitments.size
    #
    #  Just 2 days should give only 2 of them.
    #
    get @api_paths.element_commitments_path(
      @staff1.element,
      start_date: (Date.today + 1.day).strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 2, commitments.size
    #
    #  And no date at all should give us just 1 - today's.
    #
    get @api_paths.element_commitments_path(
      @staff1.element
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 1, commitments.size
  end

  test 'should be able to delete a commitment' do
    do_valid_login
    event1 = generate_event_on(Date.today,          @staff1.element)
    event2 = generate_event_on(Date.today + 1.day,  @staff1.element)
    event3 = generate_event_on(Date.today + 2.days, @staff1.element)
    #
    #  Try for all 3 days.
    #
    get @api_paths.element_commitments_path(
      @staff1.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 3, commitments.size
    #
    #  Now delete the middle one.
    #
    target_id = event2['commitments'][0]['id']

    delete @api_paths.commitment_path(target_id), params: { format: :json }
    assert_response :success

    #
    #  And there should be only 2 left.
    #
    get @api_paths.element_commitments_path(
      @staff1.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 2, commitments.size
  end

  test 'can delete event' do
    do_valid_login
    event1 = generate_event_on(Date.today,          @staff1.element)
    event2 = generate_event_on(Date.today + 1.day,  @staff1.element)
    event3 = generate_event_on(Date.today + 2.days, @staff1.element)
    #
    #  Try for all 3 days.
    #
    get @api_paths.element_commitments_path(
      @staff1.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 3, commitments.size
    #
    #  Now delete the middle event.
    #
    target_id = event2['id']

    delete @api_paths.event_path(target_id), params: { format: :json }
    assert_response :success

    #
    #  And there should be only 2 left.
    #
    get @api_paths.element_commitments_path(
      @staff1.element,
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: (Date.today + 2.days).strftime("%Y-%m-%d")
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    commitments = response_data['commitments']
    assert_instance_of Array, commitments
    assert_equal 2, commitments.size
  end

  test 'ordinary API user sees only ordinary event categories' do
    expected = Eventcategory.unprivileged.available.size
    do_valid_login
    get @api_paths.eventcategories_path, params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    eventcategories = response_data['eventcategories']
    assert_instance_of Array, eventcategories
    assert_equal expected, eventcategories.size
  end

  test 'privileged API user sees all event categories' do
    expected = Eventcategory.available.size
    do_valid_login(@privileged_api_user)
    get @api_paths.eventcategories_path, params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    eventcategories = response_data['eventcategories']
    assert_instance_of Array, eventcategories
    assert_equal expected, eventcategories.size
  end

  test 'ordinary API user can get details of ordinary event category' do
    do_valid_login
    get @api_paths.eventcategory_path(@eventcategory), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    eventcategory = response_data['eventcategory']
    assert_instance_of Hash, eventcategory
  end

  test 'but not of privileged event category' do
    do_valid_login
    get @api_paths.eventcategory_path(@privileged_eventcategory), params: { format: :json }
    assert_response :forbidden
  end

  test 'privileged API user can query any event category' do
    do_valid_login(@privileged_api_user)
    get @api_paths.eventcategory_path(@privileged_eventcategory), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    eventcategory = response_data['eventcategory']
    assert_instance_of Hash, eventcategory
  end

  test 'can get list of notes for event' do
    do_valid_login
    get @api_paths.event_notes_path(@existing_event), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    notes = response_data['notes']
    assert_instance_of Array, notes, "Notes"
    assert_equal 1, notes.size
    assert_equal @existing_note.contents, notes[0]['contents']
  end

  test 'notes request for bad event id gives not_found' do
    do_valid_login
    get @api_paths.event_notes_path(999), params: { format: :json }
    assert_response :missing
  end

  test 'can add a note to an event' do
    original_count = @existing_event.notes.count
    do_valid_login
    post @api_paths.event_notes_path(
      @existing_event,
      note: { contents: 'Hello, world!'}
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    note = response_data['note']
    assert_instance_of Hash, note
    assert_equal 'Hello, world!', note['contents']
    #
    #  And do we now see it in the list for the event?
    #
    get @api_paths.event_notes_path(@existing_event), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    notes = response_data['notes']
    assert_instance_of Array, notes, "Notes"
    assert_equal original_count + 1, notes.size
  end

  test 'can set flags on a note as we add it' do
    do_valid_login
    post @api_paths.event_notes_path(
      @existing_event,
      note: {
        contents: 'Hello, world!',
        visible_guest: true,
        visible_staff: false,
        visible_pupil: true
      }
    ), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    note = response_data['note']
    assert_instance_of Hash, note
    assert_equal 'Hello, world!', note['contents']
    assert     note['visible_guest']
    assert_not note['visible_staff']
    assert     note['visible_pupil']
  end

  test 'can get more details of a note' do
    do_valid_login
    get @api_paths.note_path(@existing_note), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    note = response_data['note']
    assert_instance_of Hash, note
    assert note.has_key? 'id'
    assert note.has_key? 'contents'
    assert note.has_key? 'visible_guest'
    assert note.has_key? 'visible_staff'
    assert note.has_key? 'visible_pupil'
    assert note.has_key? 'formatted_contents'
  end

  test 'but not of a non-existent note' do
    do_valid_login
    get @api_paths.note_path(999), params: { format: :json }
    assert_response :missing
  end

  test 'can update the contents of a note' do
    do_valid_login
    get @api_paths.note_path(@existing_note), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    note = response_data['note']
    original_contents = note['contents']
    assert_not_nil original_contents

    put @api_paths.note_path(
      @existing_note,
      note: {
        contents: 'Updated contents'
      }), params: { format: :json }
    assert_response :success
    #
    #  Check our change has been effective
    #
    get @api_paths.note_path(@existing_note), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    note = response_data['note']
    new_contents = note['contents']
    assert_equal 'Updated contents', new_contents
  end

  test 'cannot update a note belonging to someone else' do
    do_valid_login(@other_api_user)
    put @api_paths.note_path(
      @existing_note,
      note: {
        contents: 'Updated contents'
      }), params: { format: :json }
    assert_response :forbidden
  end

  test 'can delete a note from an event' do
    do_valid_login
    delete @api_paths.note_path(@existing_note), params: { format: :json }
    assert_response :success
  end

  test 'but not one which we do not own' do
    #
    #  The pre-existing note belongs to @api_user, not to @other_api_user.
    #
    do_valid_login(@other_api_user)
    delete @api_paths.note_path(@existing_note), params: { format: :json }
    assert_response :forbidden
  end

  test 'cannot delete a non-existent note' do
    do_valid_login
    delete @api_paths.note_path(999), params: { format: :json }
    assert_response :missing
  end

  test 'ordinary api user cannot list users' do
    do_valid_login
    get @api_paths.users_path, params: { format: :json }
    assert_response :forbidden
  end

  test 'su api user can list users' do
    do_valid_login(@api_user_with_su)
    get @api_paths.users_path, params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, "OK")
    users = response_data['users']
    assert_instance_of Array, users
    #
    #  But it's empty because we gave no criteria
    #
    assert_empty users
  end

  test 'invalid email produces empty list' do
    do_valid_login(@api_user_with_su)
    get @api_paths.users_path(email: "able.baker@charlie"), params: { format: :json }
    assert_response :missing
    response_data = unpack_response(response, "Not found")
    users = response_data['users']
    assert_instance_of Array, users
    assert_empty users
  end

  test 'valid email produces array of size 1' do
    do_valid_login(@api_user_with_su)
    get @api_paths.users_path(email: "api_user@myschool.org.uk"), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, "OK")
    users = response_data['users']
    assert_instance_of Array, users
    assert_equal 1, users.size
  end

  test 'api user with su can find current user id' do
    do_valid_login(@api_user_with_su)
    get @api_paths.whoami_session_path(id: 1), params: { format: :json }
    assert_response :ok
    response_data = unpack_response(response, 'OK')
    assert_equal @api_user_with_su.id, response_data['user_id'].to_i
  end

  test 'ordinary api user cannot find own user id' do
    do_valid_login
    get @api_paths.whoami_session_path(id: 1), params: { format: :json }
    assert_response :forbidden
    response_data = unpack_response(response, 'Permission denied')
    assert_nil response_data['user_id']
  end

  test 'ordinary api user cannot su' do
    do_valid_login
    put @api_paths.session_path(
      id: 1,
      session: {
        user_id: @ordinary_user.id
      }), params: { format: :json }
    assert_response :forbidden
  end

  test 'api user with su can su' do
    do_valid_login(@api_user_with_su)
    put @api_paths.session_path(
      id: 1,
      session: {
        user_id: @ordinary_user.id
      }), params: { format: :json }
    assert_response :ok
    response_data = unpack_response(response, 'OK')
    #
    #  Note that at this point we're issuing an API request, even though
    #  we are logged in as a user who doesn't have API permission.  However,
    #  since we are su'ed to being that user and our original user does
    #  have permission, it should still work.
    #
    check_i_am(@ordinary_user)
  end

  test 'api user with su cannot su to admin' do
    do_valid_login(@api_user_with_su)
    put @api_paths.session_path(
      id: 1,
      session: {
        user_id: @admin_user.id
      }), params: { format: :json }
    assert_response :forbidden
  end

  test 'su to invalid id produces error' do
    do_valid_login(@api_user_with_su)
    put @api_paths.session_path(
      id: 1,
      session: {
        user_id: 999
      }), params: { format: :json }
    assert_response :not_found
    response_data = unpack_response(response, 'Not found')
    check_i_am(@api_user_with_su)
  end

  test 'having su-ed we can revert' do
    do_valid_login(@api_user_with_su)
    #
    #  Having already tested that this works, we now delegate it
    #  to a help method.
    #
    become(@ordinary_user)
    #
    #  This is what we are actually testing now.
    #
    put @api_paths.revert_session_path(id: 1), params: { format: :json }
    assert_response :ok
    response_data = unpack_response(response, 'OK')
    check_i_am(@api_user_with_su)
  end

  test 'can revert using become functionality' do
    do_valid_login(@api_user_with_su)
    #
    #  Having already tested that this works, we now delegate it
    #  to a help method.
    #
    become(@ordinary_user)
    become(@api_user_with_su)
  end

  test 'can su and then create event as new user' do
    do_valid_login(@api_user_with_su)
    become(@ordinary_user)
    post @api_paths.events_path(event: @valid_event_params), params: { format: :json }
    assert_response 201         # Created
    response_data = unpack_response(response, "Created")
    event = response_data['event']
    assert_instance_of Hash, event
    event_id = event['id']
    get @api_paths.event_path(event_id), params: { format: :json }
    assert_response :success
    response_data = unpack_response(response, 'OK')
    event = response_data['event']
    assert_instance_of Hash, event
    owner = event['owner']
    assert_instance_of Hash, owner
    assert_equal @ordinary_user.id, owner['id'].to_i
    #
    #  And then if we revert we shouldn't be able to delete it.
    #
    revert_to_being(@api_user_with_su)
    #
    delete @api_paths.event_path(event_id), params: { format: :json }
    assert_response :forbidden
    #
    #  But as the ordinary user again, we can.
    #
    become(@ordinary_user)
    delete @api_paths.event_path(event_id), params: { format: :json }
    assert_response :ok

  end

  private

  def unpack_response(response, expected_status = nil)
    response_data = JSON.parse(response.body)
    assert_instance_of Hash, response_data
    if expected_status
      assert_equal expected_status, response_data['status']
    end
    response_data
  end

  def check_i_am(user)
    get @api_paths.whoami_session_path(id: 1), params: { format: :json }
    assert_response :ok
    response_data = unpack_response(response, 'OK')
    assert_equal user.id, response_data['user_id'].to_i
  end

  def become(user)
    put @api_paths.session_path(
      id: 1,
      session: {
        user_id: user.id
      }), params: { format: :json }
    assert_response :ok
    response_data = unpack_response(response, 'OK')
    check_i_am(user)
  end

  def revert_to_being(original_user)
    put @api_paths.revert_session_path(id: 1), params: { format: :json }
    assert_response :ok
    response_data = unpack_response(response, 'OK')
    check_i_am(original_user)
  end

  def do_valid_login(user = @api_user)
    get @api_paths.login_path(uid: user.uuid), params: { format: :json }
    assert_response :success
  end

  def do_logout
    get @api_paths.logout_path, params: { format: :json }
    assert_response :success
  end

  def do_show_element(element)
    #
    #  This handles only the positive case.  The element should
    #  exist in the database.
    #
    get @api_paths.element_path(element), params: { format: :json }
    assert_response :ok
    data = JSON.parse(response.body)
    status = data['status']
    element_data = data['element']
    assert_equal "OK", status
    assert_equal element.id, element_data['id']
    #
    #  Note that these might have a value of nil, but they should still
    #  be there.
    #
    assert element_data.key?('name')
    assert element_data.key?('entity_type')
    assert element_data.key?('entity_id')
    assert element_data.key?('current')
    case element.entity_type
    when 'Pupil'
      assert element_data.key?('email')
      assert element_data.key?('forename')
      assert element_data.key?('surname')
      assert element_data.key?('known_as')
      assert element_data.key?('year_group')
      assert element_data.key?('house_name')
    when 'Staff'
      assert element_data.key?('email')
      assert element_data.key?('title')
      assert element_data.key?('initials')
      assert element_data.key?('forename')
      assert element_data.key?('surname')
    when 'Group'
      assert element_data.key?('description')
    when 'Property'
      assert element_data.key?('make_public')
      assert element_data.key?('auto_staff')
      assert element_data.key?('auto_pupils')
    end
  end

  def check_element_summary(summary)
    assert summary.key?('id')
    assert summary.key?('name')
    assert summary.key?('entity_type')
    assert summary.key?('entity_id')
  end

  def compare_times(expected, actual)
    #
    #  expected is what we sent
    #  actual is what we got back
    #
    #  Both are strings, but formatted differently.
    #
    assert_equal Time.zone.parse(expected), Time.zone.parse(actual)
  end

  def generate_event_on(date, using = nil)
    #
    #  Generate an event on the given date, using the element or elements
    #  indicated.
    #  Pass back the structure returned from the host, which gives
    #  event id etc.
    #
    date = date.to_date         #  Just in case we've been given a time.
    start_time = date + 10.hours
    end_time = date + 11.hours
    body = "Event on #{date.strftime("%d/%m/%Y")}"
    event_params = {
      body:           body,
      starts_at_text: start_time.strftime("%d/%m/%Y %H:%M"),
      ends_at_text:   end_time.strftime("%d/%m/%Y %H:%M"),
      eventcategory_id: @eventcategory.id
    }
    if using
      if using.respond_to?(:each)
        #
        #  Treat as an array
        #
        element_ids = using.collect {|u| u.id}
      else
        element_ids = [using.id]
      end
      post @api_paths.events_path(
        event: event_params,
        elements: element_ids
      ), params: { format: :json }
    else
      post @api_paths.events_path(event: event_params), params: { format: :json }
    end
    assert_response 201         # Created
    response_data = JSON.parse(response.body)
    event = response_data['event']
    assert_instance_of Hash, event
    failures = response_data['failures']
    assert_instance_of Array, failures
    assert_empty failures
    return event
  end

end

