require 'test_helper'

class AdHocDomainPupilCourseTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @staff = FactoryBot.create(:staff)
    @pupil = FactoryBot.create(:pupil, start_year: 1990)
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

  test "pupil can be assigned via element" do
    pupil = FactoryBot.create(:pupil, name: "Charlie")
    ahdpc = FactoryBot.create(:ad_hoc_domain_pupil_course,
                              ad_hoc_domain_staff: @ad_hoc_domain_staff,
                              pupil_element: pupil.element)
    assert_equal pupil, ahdpc.pupil
  end

  test "can get pupil name directly" do
    assert @ad_hoc_domain_pupil_course.respond_to? :pupil_name
    assert_equal @ad_hoc_domain_pupil_course.pupil.name,
      @ad_hoc_domain_pupil_course.pupil_name
  end

  test "can be sorted" do
    pupil1 = FactoryBot.create(:pupil, start_year: 1991)
    pupil2 = FactoryBot.create(:pupil, start_year: 1995)
    pupil3 = FactoryBot.create(:pupil, start_year: 1993)
    ahds1 = FactoryBot.create(:ad_hoc_domain_pupil_course,
                              ad_hoc_domain_staff: @ad_hoc_domain_staff,
                              pupil: pupil1)
    ahds2 = FactoryBot.create(:ad_hoc_domain_pupil_course,
                              ad_hoc_domain_staff: @ad_hoc_domain_staff,
                              pupil: pupil2)
    ahds3 = FactoryBot.create(:ad_hoc_domain_pupil_course,
                              ad_hoc_domain_staff: @ad_hoc_domain_staff,
                              pupil: pupil3)

    @ad_hoc_domain.reload
    assert_equal [pupil2, pupil3, pupil1, @pupil],
      @ad_hoc_domain_staff.ad_hoc_domain_pupil_courses.sort.map(&:pupil)
  end

end
