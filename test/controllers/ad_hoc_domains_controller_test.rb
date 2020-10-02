require 'test_helper'

class AdHocDomainsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @admin_user = FactoryBot.create(:user, :admin)
    @eventsource = FactoryBot.create(:eventsource)
    @eventcategory = FactoryBot.create(:eventcategory)
    @datasource = FactoryBot.create(:datasource)
    @ordinary_user = FactoryBot.create(:user)
    do_valid_login
  end

  test "should get index" do
    get ad_hoc_domains_url
    assert_response :success
  end

  test "should get new" do
    get new_ad_hoc_domain_url
    assert_response :success
  end

  test "should create ad_hoc_domain" do
    assert_difference('AdHocDomain.count') do
      post ad_hoc_domains_url, params: {
        ad_hoc_domain: {
          name: @ad_hoc_domain.name,
          eventsource_id: @eventsource.id,
          eventcategory_id: @eventcategory.id,
          datasource_id: @datasource.id
        } 
      }
    end

    assert_redirected_to ad_hoc_domains_url
  end

  test "should get edit" do
    get edit_ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
  end

  test "should update ad_hoc_domain" do
    patch ad_hoc_domain_url(@ad_hoc_domain), params: { ad_hoc_domain: { name: @ad_hoc_domain.name } }
    assert_redirected_to ad_hoc_domains_url
  end

  test "should destroy ad_hoc_domain" do
    assert_difference('AdHocDomain.count', -1) do
      delete ad_hoc_domain_url(@ad_hoc_domain)
    end

    assert_redirected_to ad_hoc_domains_url
  end

  test "should get edit controllers" do
    get edit_controllers_ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
  end

  test "should add controller via html" do
    assert_difference('@ad_hoc_domain.controllers.count') do
      patch add_controller_ad_hoc_domain_url(@ad_hoc_domain),
        params: { ad_hoc_domain: { new_controller_id: @ordinary_user.id } }
      assert_response :success
    end
  end

  test "blank id does nothing" do
    assert_difference('@ad_hoc_domain.controllers.count', 0) do
      patch add_controller_ad_hoc_domain_url(@ad_hoc_domain),
        params: { ad_hoc_domain: { new_controller_id: "" } }
      assert_response :success
    end
  end

  test "should add controller via ajax" do
    assert_difference('@ad_hoc_domain.controllers.count') do
      patch add_controller_ad_hoc_domain_url(@ad_hoc_domain),
        params: { format: 'js', ad_hoc_domain: { new_controller_id: @ordinary_user.id } }
      assert_response :success
    end
  end

  private 

  def do_valid_login(user = @admin_user)
    put test_login_path(user_id: user.id)
    assert_redirected_to '/'
  end

end
