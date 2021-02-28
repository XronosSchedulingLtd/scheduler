require 'test_helper'

class AdHocDomainSubjectsControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @ad_hoc_domain_cycle = FactoryBot.create(
      :ad_hoc_domain_cycle,
      ad_hoc_domain: @ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
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
  end

  test "should delete ad_hoc_domain_subject" do
    session[:user_id] = @admin_user.id
    ahds = FactoryBot.create(:ad_hoc_domain_subject)
    assert_difference('AdHocDomainSubject.count', -1) do
      delete :destroy,
        params: {
          id: ahds
        },
        xhr: true
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'delete_subject'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
  end

end
