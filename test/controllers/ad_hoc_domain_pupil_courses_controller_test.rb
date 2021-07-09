require 'test_helper'

class AdHocDomainPupilCoursesControllerTest < ActionController::TestCase
  setup do
    @ad_hoc_domain_subject_staff =
      FactoryBot.create(:ad_hoc_domain_subject_staff)
    @pupil = FactoryBot.create(:pupil)
    @admin_user = FactoryBot.create(:user, :admin)
    @ad_hoc_domain_pupil_course =
      FactoryBot.create(
        :ad_hoc_domain_pupil_course,
        ad_hoc_domain_subject_staff: @ad_hoc_domain_subject_staff)
  end

  test "should create ad_hoc_pupil_course" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainPupilCourse.count') do
      post :create,
        params: {
          ad_hoc_domain_subject_staff_id: @ad_hoc_domain_subject_staff,
          ad_hoc_domain_pupil_course: {
            pupil_element_id: @pupil.element
          } 
        },
        xhr: true
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'new_pupil_listing'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
  end

  test "should fail to create two identical" do
    session[:user_id] = @admin_user.id
    assert_difference('AdHocDomainPupilCourse.count') do
      post :create,
        params: {
          ad_hoc_domain_subject_staff_id: @ad_hoc_domain_subject_staff,
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
          ad_hoc_domain_subject_staff_id: @ad_hoc_domain_subject_staff,
          ad_hoc_domain_pupil_course: {
            pupil_element_id: @pupil.element
          } 
        },
        xhr: true
    end
    assert_response :conflict
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'show_pupil_error'/ =~ response.body
    assert /staff_id:/ =~ response.body
    assert /subject_id:/ =~ response.body
    assert /error_text:/ =~ response.body
  end

  test "should delete ad_hoc_pupil_course" do
    session[:user_id] = @admin_user.id
    ahdpc = FactoryBot.create(
      :ad_hoc_domain_pupil_course,
      ad_hoc_domain_subject_staff: @ad_hoc_domain_subject_staff)
    assert_difference('AdHocDomainPupilCourse.count', -1) do
      delete :destroy,
        params: {
          id: ahdpc
        },
        xhr: true
    end
    assert_response :success
    assert /^window.ahdUpdate\(/ =~ response.body
    assert /action: 'new_pupil_listing'/ =~ response.body
    assert /action: 'clear_errors'/ =~ response.body
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
    assert_equal org_mins + 15, data['minutes']
    assert_not_nil data['staff_id']
    assert_not_nil data['staff_total']
    assert_not_nil data['subject_id']
    assert_not_nil data['subject_total']
    #
    #  And that it's been saved on the host.
    #
    @ad_hoc_domain_pupil_course.reload
    assert_equal org_mins + 15, @ad_hoc_domain_pupil_course.minutes
    #
    #  And now provoke an error.
    #
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
    assert_equal @ad_hoc_domain_subject_staff.ad_hoc_domain_subject_id,
      data['subject_id']
    assert_equal @ad_hoc_domain_subject_staff.ad_hoc_domain_staff_id,
      data['staff_id']
    assert_equal 'is not a number', data['errors']['minutes'][0]
  end

end
