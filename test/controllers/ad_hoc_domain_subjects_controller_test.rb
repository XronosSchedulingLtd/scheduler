require 'test_helper'

class AdHocDomainSubjectsControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @admin_user = FactoryBot.create(:user, :admin)
    @eventsource = FactoryBot.create(:eventsource)
    @eventcategory = FactoryBot.create(:eventcategory)
    @datasource = FactoryBot.create(:datasource)
    @ordinary_user = FactoryBot.create(:user)
  end

  test "should create ad_hoc_domain" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainSubject.count') do
      post :create,
        params: {
          ad_hoc_domain_id: @ad_hoc_domain,
          ad_hoc_domain_subject: {
            subject_element_id: @subject.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert /^document.getElementById\('ahd-subject-list'/ =~ response.body
  end

  test "should fail to create two identical" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainSubject.count') do
      post :create,
        params: {
          ad_hoc_domain_id: @ad_hoc_domain,
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
          ad_hoc_domain_id: @ad_hoc_domain,
          ad_hoc_domain_subject: {
            subject_element_id: @subject.element
          } 
        },
        xhr: true
    end
    assert_response :conflict
    assert /^document.getElementById\('ahd-subject-errors'/ =~ response.body
  end

  test "should delete ad_hoc_domain" do
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
    assert /^document.getElementById\('ahd-subject-list'/ =~ response.body
  end

end
