require 'test_helper'

class AdHocDomainPupilCoursesControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain_staff = FactoryBot.create(:ad_hoc_domain_staff)
    @pupil = FactoryBot.create(:pupil)
    @admin_user = FactoryBot.create(:user, :admin)
  end

  test "should create ad_hoc_pupil_course" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainPupilCourse.count') do
      post :create,
        params: {
          ad_hoc_domain_staff_id: @ad_hoc_domain_staff,
          ad_hoc_domain_pupil_course: {
            pupil_element_id: @pupil.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert /^document.getElementById\('ahd-staff-pupils-#{@ad_hoc_domain_staff.id}'/ =~ response.body
    assert /document.getElementById\('pupil-element-name-#{@ad_hoc_domain_staff.id}'\)\.focus/ =~ response.body
  end

  test "should fail to create two identical" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainPupilCourse.count') do
      post :create,
        params: {
          ad_hoc_domain_staff_id: @ad_hoc_domain_staff,
          ad_hoc_domain_pupil_course: {
            pupil_element_id: @pupil.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert_difference('AdHocDomainPupilCourse.count', 0) do
      post :create,
        params: {
          ad_hoc_domain_staff_id: @ad_hoc_domain_staff,
          ad_hoc_domain_pupil_course: {
            pupil_element_id: @pupil.element
          } 
        },
        xhr: true
    end
    assert_response :conflict
    assert /^document.getElementById\('ahd-pupil-errors-#{@ad_hoc_domain_staff.id}'/ =~ response.body
  end

  test "should delete ad_hoc_pupil_course" do
    session[:user_id] = @admin_user.id
    ahdpc = FactoryBot.create(
      :ad_hoc_domain_pupil_course,
      ad_hoc_domain_staff: @ad_hoc_domain_staff)
    assert_difference('AdHocDomainPupilCourse.count', -1) do
      delete :destroy,
        params: {
          id: ahdpc
        },
        xhr: true
    end
    assert_response :success
    assert /^document.getElementById\('ahd-staff-pupils-#{@ad_hoc_domain_staff.id}'\)/ =~ response.body
    assert /document.getElementById\('pupil-element-name-#{@ad_hoc_domain_staff.id}'\)\.focus/ =~ response.body
  end

end
