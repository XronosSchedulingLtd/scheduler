require 'test_helper'

class AdHocDomainSubjectsControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @ad_hoc_domain_cycle = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @staff = FactoryBot.create(:staff)
    @admin_user = FactoryBot.create(:user, :admin)
    @eventsource = FactoryBot.create(:eventsource)
    @eventcategory = FactoryBot.create(:eventcategory)
    @datasource = FactoryBot.create(:datasource)
    @ordinary_user = FactoryBot.create(:user)
  end

  test "should create ad_hoc_domain subject" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainSubject.count') do
      post :create,
        params: {
          ad_hoc_domain_cycle_id: @ad_hoc_domain_cycle,
          ad_hoc_domain_subject: {
            subject_element_id: @subject.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'add_subject'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
  end

  test "should fail to create two identical" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainSubject.count') do
      post :create,
        params: {
          ad_hoc_domain_cycle_id: @ad_hoc_domain_cycle,
          ad_hoc_domain_subject: {
            subject_element_id: @subject.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert_difference('AdHocDomainSubject.count', 0) do
      post :create,
        params: {
          ad_hoc_domain_cycle_id: @ad_hoc_domain_cycle,
          ad_hoc_domain_subject: {
            subject_element_id: @subject.element
          } 
        },
        xhr: true
    end
    assert_response :conflict
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'show_error'/ =~ response.body
    assert /selector: '#ahd-subject-errors-c/ =~ response.body
  end

  test "should delete ad_hoc_domain_subject" do
    session[:user_id] = @admin_user.id
    ahd_subject = FactoryBot.create(
      :ad_hoc_domain_subject,
      ad_hoc_domain_cycle: @ad_hoc_domain_cycle)
    ahd_staff = FactoryBot.create(
      :ad_hoc_domain_staff,
      ad_hoc_domain_cycle: @ad_hoc_domain_cycle)
    FactoryBot.create(
      :ad_hoc_domain_subject_staff,
      ad_hoc_domain_subject: ahd_subject,
      ad_hoc_domain_staff: ahd_staff)
    assert_difference('AdHocDomainSubject.count', -1) do
      assert_difference('AdHocDomainSubjectStaff.count', -1) do
        delete :destroy,
          params: {
            id: ahd_subject
          },
          xhr: true
      end
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'delete_subject'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
    assert /action: 'update_staff_subjects'/ =~ response.body
  end

  test "can link existing subject to existing staff" do
    session[:user_id] = @admin_user.id
    ahd_subject =
      FactoryBot.create(
        :ad_hoc_domain_subject,
        ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
        subject_element_id: @subject.element)
    ahd_staff =
      FactoryBot.create(
        :ad_hoc_domain_staff,
        ad_hoc_domain_cycle: @ad_hoc_domain_cycle)
    assert_difference('AdHocDomainSubjectStaff.count') do
      post :create,
        params: {
          ad_hoc_domain_staff_id: ahd_staff,
          ad_hoc_domain_subject: {
            subject_element_id: @subject.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'update_subject_staff'/ =~ response.body
    assert /action: 'update_staff_subjects'/ =~ response.body
    assert /action: 'update_staff_totals'/ =~ response.body
    assert /action: 'update_subject_totals'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
  end

end
