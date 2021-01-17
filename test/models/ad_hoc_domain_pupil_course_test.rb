require 'test_helper'

class AdHocDomainPupilCourseTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @staff = FactoryBot.create(:staff)
    @pupil = FactoryBot.create(:pupil)
    @ad_hoc_domain_subject =
      FactoryBot.create(
        :ad_hoc_domain_subject,
        ad_hoc_domain: @ad_hoc_domain,
        subject: @subject)
    @ad_hoc_domain_staff =
      FactoryBot.create(
        :ad_hoc_domain_staff,
        staff: @staff,
        ad_hoc_domain_subject: @ad_hoc_domain_subject)
    @ad_hoc_domain_pupil_course =
      FactoryBot.create(
        :ad_hoc_domain_pupil_course,
        pupil: @pupil,
        ad_hoc_domain_staff: @ad_hoc_domain_staff)
  end

  test "can be valid" do
    assert @ad_hoc_domain_pupil_course.valid?
  end

  test "must have a staff" do
    ahdpc = FactoryBot.build(:ad_hoc_domain_pupil_course, ad_hoc_domain_staff: nil)
    assert_not ahdpc.valid?
  end

  test "must have a pupil" do
    ahdpc = FactoryBot.build(:ad_hoc_domain_pupil_course, pupil: nil)
    assert_not ahdpc.valid?
  end

  test "must be unique" do
    second = FactoryBot.build(
      :ad_hoc_domain_pupil_course,
      pupil: @pupil,
      ad_hoc_domain_staff: @ad_hoc_domain_staff)
    assert_not second.valid?    # Because it's the same as the first one
  end

end
