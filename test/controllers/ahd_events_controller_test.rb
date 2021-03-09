require 'test_helper'

class AhdEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = FactoryBot.create(:user, :admin)
    @ordinary_user = FactoryBot.create(:user)
    #
    @ad_hoc_domain_staff = FactoryBot.create(
      :ad_hoc_domain_staff)
    @ad_hoc_domain_cycle = @ad_hoc_domain_staff.ad_hoc_domain_cycle
    @ad_hoc_domain = @ad_hoc_domain_cycle.ad_hoc_domain
    @ad_hoc_domain.default_day_shape = FactoryBot.create(:rota_template)
    @ad_hoc_domain.save
    #
    #  Normally the staff record would gain its rota_template when
    #  the user first tried to view it, but we're bypassing that
    #  step and going straight to the queries so we need to explicitly
    #  add one.
    #
    @ad_hoc_domain_staff.rota_template =
      FactoryBot.create(:rota_template, :no_slots)
    @ad_hoc_domain_staff.save
    do_valid_login
  end

  test "should get index" do
    get ad_hoc_domain_staff_events_url(@ad_hoc_domain_staff), as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data.is_a? Array
    sample = data[0]
    assert sample.is_a? Hash
    assert sample.has_key? 'start'
    assert sample.has_key? 'end'
    assert sample.has_key? 'rendering'
    assert_equal 'background', sample['rendering']
  end

  test "can create event" do
    #
    #  As we currently have no events, this should add a rota_slot
    #  to our rota_template.
    #
    assert_difference('@ad_hoc_domain_staff.rota_template.rota_slots.count') do
      post ad_hoc_domain_staff_events_url(@ad_hoc_domain_staff),
        as: :json,
        params: {
          ahd_event: {
            starts_at: "2017-01-02 10:00",
            ends_at: "2017-01-02 10:05"
          }
        }
      assert_response :success
    end
    #
    #  But this one shouldn't.  It should affect the existing RotaSlot.
    #
    assert_difference('@ad_hoc_domain_staff.rota_template.rota_slots.count', 0) do
      post ad_hoc_domain_staff_events_url(@ad_hoc_domain_staff),
        as: :json,
        params: {
          ahd_event: {
            starts_at: "2017-01-03 10:00",
            ends_at: "2017-01-03 10:05"
          }
        }
      assert_response :success
    end
  end

  private 

  def do_valid_login(user = @admin_user)
    put test_login_path(user_id: user.id)
    assert_redirected_to '/'
  end

end
