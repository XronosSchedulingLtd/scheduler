require 'test_helper'

class AdHocDomainCyclesControllerTest < ActionDispatch::IntegrationTest
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

  test "can get new" do
    get new_ad_hoc_domain_ad_hoc_domain_cycle_path(@ad_hoc_domain)
    assert_response :success
  end

  test "can create new cycle" do
    assert_difference('AdHocDomainCycle.count') do
      post ad_hoc_domain_ad_hoc_domain_cycles_url(@ad_hoc_domain), params: {
        ad_hoc_domain_cycle: {
          name: "New cycle",
          starts_on: Date.today,
          ends_on: Date.tomorrow
        } 
      }
    end
    assert_redirected_to ad_hoc_domain_url(@ad_hoc_domain, params: { tab: 0 })
  end

  test "can set cycle as default" do
    cycle1 = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain,
      name: "Cycle 1",
      starts_on: Date.today,
      exclusive_end_date: Date.today + 2.days)
    cycle2 = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain,
      name: "Cycle 2",
      starts_on: Date.today + 7.days,
      exclusive_end_date: Date.today + 9.days)

    #
    #  As cycle 2 is later, it should be used by default.
    #
    get ad_hoc_domain_url(@ad_hoc_domain)
    assert_response :success
    #
    document = Nokogiri::HTML(response.body)
    sub_head = document.at_css("h4")
    assert /Cycle 2/ =~ sub_head.text

    put set_as_default_ad_hoc_domain_cycle_url(cycle1)
    assert_redirected_to ad_hoc_domain_url(@ad_hoc_domain, params: { tab: 0 })

    get ad_hoc_domain_url(@ad_hoc_domain, params: { tab: 0 })
    assert_response :success
    #
    document = Nokogiri::HTML(response.body)
    sub_head = document.at_css("h4")
    assert /Cycle 1/ =~ sub_head.text
    #
    #  And we should be on tab 0 of three.
    #
    titles = document.css('li.tab-title')
    assert_equal 3, titles.count
    assert /active/ =~ titles[0].attributes['class'].value
    assert_equal 1, document.css('li.tab-title.active').count
  end

  private 

  def do_valid_login(user = @admin_user)
    put test_login_path(user_id: user.id)
    assert_redirected_to '/'
  end

end
