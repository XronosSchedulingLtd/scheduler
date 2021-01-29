require 'test_helper'

class AdHocDomainPupilCoursesControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain_staff = FactoryBot.create(:ad_hoc_domain_staff)
    @pupil = FactoryBot.create(:pupil)
    @admin_user = FactoryBot.create(:user, :admin)
    @ad_hoc_domain_pupil_course = FactoryBot.create(:ad_hoc_domain_pupil_course)
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

  test "can update minutes via ajax" do
    session[:user_id] = @admin_user.id
    org_mins = @ad_hoc_domain_pupil_course.minutes
#    patch set_mins_ad_hoc_domain_pupil_course_path(
    patch :update,
      params: {
        id: @ad_hoc_domain_pupil_course,
        ad_hoc_domain_pupil_course: {
          minutes: org_mins + 15
        }
      },
      format: :json
    assert_response :success
    data = JSON.parse(response.body)
    #
    #  Check new value is in response.
    #
    assert_equal @ad_hoc_domain_pupil_course.id, data['id']
    assert_equal @ad_hoc_domain_pupil_course.owner_id, data['owner_id']
    assert_equal org_mins + 15, data['minutes']
    #
    #  And that it's been saved on the host.
    #
    @ad_hoc_domain_pupil_course.reload
    assert_equal org_mins + 15, @ad_hoc_domain_pupil_course.minutes
    patch :update,
      params: {
        id: @ad_hoc_domain_pupil_course,
        ad_hoc_domain_pupil_course: {
          minutes: "Banana"
        }
      },
      format: :json
    assert_response 422
    data = JSON.parse(response.body)
    assert_equal @ad_hoc_domain_pupil_course.id, data['id']
    assert_equal @ad_hoc_domain_pupil_course.owner_id, data['owner_id']
    assert_equal 'is not a number', data['errors']['minutes'][0]
  end

end
