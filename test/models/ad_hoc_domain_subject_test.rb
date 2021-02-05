require 'test_helper'

class AdHocDomainSubjectTest < ActiveSupport::TestCase
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
  end

  test "can be valid" do
    assert @ad_hoc_domain_subject.valid?
  end

  test "must have a cycle" do
    ahds = FactoryBot.build(:ad_hoc_domain_subject, ad_hoc_domain_cycle: nil)
    assert_not ahds.valid?
  end

  test "must have a subject" do
    ahds = FactoryBot.build(:ad_hoc_domain_subject, subject: nil)
    assert_not ahds.valid?
  end

  test "can get subject name directly" do
    assert @ad_hoc_domain_subject.respond_to? :subject_name
    assert_equal @ad_hoc_domain_subject.subject.name,
      @ad_hoc_domain_subject.subject_name
  end

  test "must be unique" do
    second = FactoryBot.build(
      :ad_hoc_domain_subject,
      ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
      subject: @subject)
    assert_not second.valid?    # Because it's the same as the first one
  end

  test "can be sorted" do
    subject1 = FactoryBot.create(:subject, name: "Charlie")
    subject2 = FactoryBot.create(:subject, name: "Able")
    subject3 = FactoryBot.create(:subject, name: "Baker")
    ahds1 = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
                              subject: subject1)
    ahds2 = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
                              subject: subject2)
    ahds3 = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
                              subject: subject3)

    @ad_hoc_domain_cycle.reload
    assert_equal [subject2, subject3, subject1, @subject],
      @ad_hoc_domain_cycle.ad_hoc_domain_subjects.sort.map(&:subject)
  end

  test "subject can be assigned via element" do
    subject = FactoryBot.create(:subject, name: "Charlie")
    ahds = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
                              subject_element: subject.element)
    assert_equal subject, ahds.subject
  end

  test "can have staff" do
    assert @ad_hoc_domain_subject.respond_to? :staffs
    assert @ad_hoc_domain_subject.respond_to? :ad_hoc_domain_staffs
  end

  test "can compute number of staff and number of pupils" do
    assert @ad_hoc_domain_subject.respond_to? :num_real_staff
    assert @ad_hoc_domain_subject.respond_to? :num_real_pupils
    staff1 = FactoryBot.create(
      :ad_hoc_domain_staff,
      ad_hoc_domain_subject: @ad_hoc_domain_subject)
    staff2 = FactoryBot.create(
      :ad_hoc_domain_staff,
      ad_hoc_domain_subject: @ad_hoc_domain_subject)
    #
    #  This next one should not be counted.
    #
    blank_staff = @ad_hoc_domain_subject.ad_hoc_domain_staffs.new
    assert_equal 2, @ad_hoc_domain_subject.num_real_staff
    pupil1 = FactoryBot.create(
      :ad_hoc_domain_pupil_course,
      ad_hoc_domain_staff: staff1)
    pupil2 = FactoryBot.create(
      :ad_hoc_domain_pupil_course,
      ad_hoc_domain_staff: staff2)
    blank_pupil = staff1.ad_hoc_domain_pupil_courses.new
    assert_equal 2, @ad_hoc_domain_subject.num_real_pupils
  end

  test "can access domain directly" do
    assert_equal @ad_hoc_domain, @ad_hoc_domain_subject.ad_hoc_domain
  end

end
