require 'test_helper'

class AdHocDomainsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = FactoryBot.create(:user, :admin)
    @ordinary_user = FactoryBot.create(:user)
    #
    @eventsource = FactoryBot.create(:eventsource)
    @eventcategory = FactoryBot.create(:eventcategory)
    @datasource = FactoryBot.create(:datasource)
    @property = FactoryBot.create(:property)
    #
    @ad_hoc_domain = FactoryBot.create(
      :ad_hoc_domain,
      eventsource: @eventsource,
      eventcategory: @eventcategory,
      connected_property: @property,
      datasource: @datasource)
    do_valid_login
  end

  test "should get index" do
    get ad_hoc_domains_url
    assert_response :success
  end

  test "should show domain" do
    get ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
    #
    #  As there are no cycles defined yet, we should get just the one
    #  tab and it should be active.
    #
    document = Nokogiri::HTML(response.body)
    assert_equal 1, document.css('li.tab-title').count
    assert_equal 1, document.css('li.tab-title.active').count
    assert_equal 1, document.css('div.content').count
    assert_equal 1, document.css('div.content.active').count
  end

  test "with a cycle should show second of three tabs" do
    FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain)
    get ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
    #
    document = Nokogiri::HTML(response.body)
    titles = document.css('li.tab-title')
    assert_equal 4, titles.count
    assert /active/ =~ titles[1].attributes['class'].value
    assert_equal 1, document.css('li.tab-title.active').count
    bodies = document.css('div.content')
    assert_equal 4, bodies.count
    assert /active/ =~ bodies[1].attributes['class'].value
    assert_equal 1, document.css('div.content.active').count
  end

  test "request can override which tab is shown" do
    FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain)
    get ad_hoc_domain_url(@ad_hoc_domain, params: { tab: 0 })
    assert_response :success
    #
    document = Nokogiri::HTML(response.body)
    titles = document.css('li.tab-title')
    assert_equal 4, titles.count
    assert /active/ =~ titles[0].attributes['class'].value
    assert_equal 1, document.css('li.tab-title.active').count
    bodies = document.css('div.content')
    assert_equal 4, bodies.count
    assert /active/ =~ bodies[0].attributes['class'].value
    assert_equal 1, document.css('div.content.active').count


    get ad_hoc_domain_url(@ad_hoc_domain, params: { tab: 2 })
    assert_response :success
    #
    document = Nokogiri::HTML(response.body)
    titles = document.css('li.tab-title')
    assert_equal 4, titles.count
    assert /active/ =~ titles[2].attributes['class'].value
    assert_equal 1, document.css('li.tab-title.active').count
    bodies = document.css('div.content')
    assert_equal 4, bodies.count
    assert /active/ =~ bodies[2].attributes['class'].value
    assert_equal 1, document.css('div.content.active').count
  end

  test "can choose which cycle to show" do
    earlier_cycle = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain,
      name: "Earlier",
      starts_on: Date.today,
      exclusive_end_date: Date.today + 3.days)
    later_cycle = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain,
      name: "Later",
      starts_on: Date.today + 7.days,
      exclusive_end_date: Date.today + 10.days)
    @ad_hoc_domain.reload
    get ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
    document = Nokogiri::HTML(response.body)
    sub_head = document.at_css("h4")
    assert /Later/ =~ sub_head.text
    #
    get ad_hoc_domain_url(@ad_hoc_domain,
                          params: { cycle_id: earlier_cycle.id })
    assert_response :success
    document = Nokogiri::HTML(response.body)
    sub_head = document.at_css("h4")
    assert /Earlier/ =~ sub_head.text
  end

  test "setting a default cycle causes it to show" do
    earlier_cycle = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain,
      name: "Earlier",
      starts_on: Date.today,
      exclusive_end_date: Date.today + 3.days)
    later_cycle = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain,
      name: "Later",
      starts_on: Date.today + 7.days,
      exclusive_end_date: Date.today + 10.days)
    @ad_hoc_domain.reload
    get ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
    document = Nokogiri::HTML(response.body)
    sub_head = document.at_css("h4")
    assert /Later/ =~ sub_head.text
    #
    @ad_hoc_domain.default_cycle = earlier_cycle
    @ad_hoc_domain.save
    get ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
    document = Nokogiri::HTML(response.body)
    sub_head = document.at_css("h4")
    assert /Earlier/ =~ sub_head.text
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
