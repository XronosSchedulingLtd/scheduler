require 'test_helper'

class AdHocDomainStaffsControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @ad_hoc_domain_cycle =
      FactoryBot.create(
        :ad_hoc_domain_cycle,
        ad_hoc_domain: @ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @ad_hoc_domain_subject =
      FactoryBot.create(
        :ad_hoc_domain_subject,
        ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
        subject: @subject)
    @staff = FactoryBot.create(:staff)
    @admin_user = FactoryBot.create(:user, :admin)
    @eventsource = FactoryBot.create(:eventsource)
    @eventcategory = FactoryBot.create(:eventcategory)
    @datasource = FactoryBot.create(:datasource)
    @ordinary_user = FactoryBot.create(:user)
  end

  test "should create ad_hoc_domain_staff" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainStaff.count') do
      post :create,
        params: {
          ad_hoc_domain_cycle_id: @ad_hoc_domain_cycle,
          ad_hoc_domain_staff: {
            staff_element_id: @staff.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'add_staff'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
  end

  test "should fail to create two identical" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainStaff.count') do
      post :create,
        params: {
          ad_hoc_domain_cycle_id: @ad_hoc_domain_cycle,
          ad_hoc_domain_staff: {
            staff_element_id: @staff.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert_difference('AdHocDomainStaff.count', 0) do
      post :create,
        params: {
          ad_hoc_domain_cycle_id: @ad_hoc_domain_cycle,
          ad_hoc_domain_staff: {
            staff_element_id: @staff.element
          } 
        },
        xhr: true
    end
    assert_response :conflict
    assert /^document.getElementById\('ahd-staff-errors-#{@ad_hoc_domain_cycle.id_suffix}'/ =~ response.body
  end

  test "should delete ad_hoc_domain_staff" do
    session[:user_id] = @admin_user.id
    ahds = FactoryBot.create(
      :ad_hoc_domain_staff,
      ad_hoc_domain_cycle: @ad_hoc_domain_cycle)
    FactoryBot.create(
      :ad_hoc_domain_subject_staff,
      ad_hoc_domain_subject: @ad_hoc_domain_subject,
      ad_hoc_domain_staff: ahds)

    assert_difference('AdHocDomainStaff.count', -1) do
      assert_difference('AdHocDomainSubjectStaff.count', -1) do
        delete :destroy,
          params: {
            id: ahds
          },
          xhr: true
      end
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'delete_staff'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
    assert /action: 'update_subject_staff'/ =~ response.body
  end

end
