require 'test_helper'

class ApiTest < ActionDispatch::IntegrationTest
  setup do
    @api_user = FactoryBot.create(:user, :api)
    @ordinary_user = FactoryBot.create(:user)
    @staff1 = FactoryBot.create(
      :staff, {name: "Able Baker Charlie", initials: "ABC"})
    @pupil1 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Maximus")
    @pupil2 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Major")
    @pupil3 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Minor")
    @pupil4 = FactoryBot.create(:pupil, name: "Fotheringay-Smith Minimus")

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
    get @api_paths.login_path(uid: 'ablebakercharlie'), format: :json
    assert_response 401
  end

  test "ordinary user cannot log in through api" do
    get @api_paths.login_path(uid: @ordinary_user.uuid), format: :json
    assert_response 401
  end

  test "api user can log in through api" do
    get @api_paths.login_path(uid: @api_user.uuid), format: :json
    assert_response :success
  end

  test "logout requests must be json" do
    get @api_paths.logout_path
    assert_redirected_to "/"
  end

  test "logout always succeeds" do
    get @api_paths.logout_path, format: :json
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
    get @api_paths.elements_path, format: :json
    assert_response 401
    #
    #  Then login and we can.
    #
    do_valid_login
    get @api_paths.elements_path, format: :json
    assert_response :success
    #
    #  Then logout and we can't again.
    #
    do_logout
    get @api_paths.elements_path, format: :json
    assert_response 401
  end

  #
  #  Now test the elements controller.
  #
  test "index with no params gets empty response" do
    do_valid_login
    get @api_paths.elements_path, format: :json
    assert_response :success
    data = JSON.parse(response.body)
    status = data['status']
    elements = data['elements']
    assert_equal "OK", status
    #
    #  elements should be an empty array.
    #
    assert_instance_of Array, elements
    assert_empty elements
  end

  test "search for non-existent element returns appropriate error" do
    do_valid_login
    get @api_paths.elements_path(name: 'Banana fritter'), format: :json
    assert_response :missing
  end

  test "search for existing element finds it" do
    do_valid_login
    get @api_paths.elements_path(name: 'ABC - Able Baker Charlie'),
        format: :json
    assert_response :success
    data = JSON.parse(response.body)
    status = data['status']
    elements = data['elements']
    assert_equal "OK", status
    assert_instance_of Array, elements
    assert_equal 1, elements.size
  end

  test "fuzzy search for non-existent element returns appropriate error" do
    do_valid_login
    get @api_paths.elements_path(namelike: 'Banana fritter'), format: :json
    assert_response :missing
  end

  test "fuzzy search finds existing elements" do
    do_valid_login
    get @api_paths.elements_path(namelike: 'Fotheringay'),
        format: :json
    assert_response :success
    data = JSON.parse(response.body)
    status = data['status']
    elements = data['elements']
    assert_equal "OK", status
    assert_instance_of Array, elements
    assert_equal 4, elements.size
  end

  test "element show with invalid id returns appropriate error" do
    do_valid_login
    get @api_paths.element_path(id: 999), format: :json
    assert_response :missing
    data = JSON.parse(response.body)
    status = data['status']
    assert_equal "Not found", status
  end

  test "element show succeeds for valid staff element" do
    do_valid_login
    get @api_paths.element_path(@staff1.element), format: :json
    assert_response :ok
    data = JSON.parse(response.body)
    status = data['status']
    element = data['element']
    assert_equal "OK", status
    assert_equal @staff1.element.id, element['id']
    #
    #  Note that these might have a value of nil, but they should still
    #  be there.
    #
    assert element.key?('name')
    assert element.key?('entity_type')
    assert element.key?('entity_id')
    assert element.key?('current')
    #
    #  Stuff specific to it being a staff element.
    #
    assert element.key?('email')
    assert element.key?('title')
    assert element.key?('initials')
    assert element.key?('forename')
    assert element.key?('surname')
  end

  test "element show succeeds for valid pupil element" do
    do_valid_login
    get @api_paths.element_path(@pupil1.element), format: :json
    assert_response :ok
    data = JSON.parse(response.body)
    status = data['status']
    element = data['element']
    assert_equal "OK", status
    assert_equal @pupil1.element.id, element['id']
    #
    #  Note that these might have a value of nil, but they should still
    #  be there.
    #
    assert element.key?('name')
    assert element.key?('entity_type')
    assert element.key?('entity_id')
    assert element.key?('current')
    #
    #  Stuff specific to it being a pupil element.
    #
    assert element.key?('email')
    assert element.key?('forename')
    assert element.key?('surname')
    assert element.key?('known_as')
    assert element.key?('year_group')
    assert element.key?('house_name')
  end

  private

  def do_valid_login
    get @api_paths.login_path(uid: @api_user.uuid), format: :json
    assert_response :success
  end

  def do_logout
    get @api_paths.logout_path, format: :json
    assert_response :success
  end

end

