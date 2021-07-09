require 'test_helper'

class AdHocDomainSubjectStaffTest < ActiveSupport::TestCase
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
    @ad_hoc_domain_staff =
      FactoryBot.create(
        :ad_hoc_domain_staff,
        ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
        staff: @staff)
    @ad_hoc_domain_subject_staff =
      FactoryBot.create(
        :ad_hoc_domain_subject_staff,
        ad_hoc_domain_subject: @ad_hoc_domain_subject,
        ad_hoc_domain_staff: @ad_hoc_domain_staff)
  end

  test "can be valid" do
    assert @ad_hoc_domain_subject_staff.valid?
  end

  test "must have a subject" do
    ahdss = FactoryBot.build(
      :ad_hoc_domain_subject_staff,
      ad_hoc_domain_subject: nil)
    assert_not ahdss.valid?
  end

  test "must have a staff" do
    ahdss = FactoryBot.build(
      :ad_hoc_domain_subject_staff,
      ad_hoc_domain_staff: nil)
    assert_not ahdss.valid?
  end

  test "must be unique" do
    second = FactoryBot.build(
      :ad_hoc_domain_subject_staff,
      ad_hoc_domain_subject: @ad_hoc_domain_subject,
      ad_hoc_domain_staff: @ad_hoc_domain_staff)
    assert_not second.valid?    # Because it's the same as the first one
  end

  test "can have pupil courses" do
    assert @ad_hoc_domain_subject_staff.respond_to? :ad_hoc_domain_pupil_courses
  end

  test "deleting this record deletes pupil courses" do
    ahdpc1 = FactoryBot.create(
      :ad_hoc_domain_pupil_course, 
      ad_hoc_domain_subject_staff: @ad_hoc_domain_subject_staff)
    ahdpc2 = FactoryBot.create(
      :ad_hoc_domain_pupil_course, 
      ad_hoc_domain_subject_staff: @ad_hoc_domain_subject_staff)
    assert_difference('AdHocDomainPupilCourse.count', -2) do
      @ad_hoc_domain_subject_staff.destroy
    end
  end

end
