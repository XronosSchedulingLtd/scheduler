require 'test_helper'

class AdHocDomainSubjectTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @ad_hoc_domain_subject =
      FactoryBot.create(
        :ad_hoc_domain_subject,
        ad_hoc_domain: @ad_hoc_domain,
        subject: @subject)
  end

  test "can be valid" do
    assert @ad_hoc_domain_subject.valid?
  end

  test "must have a domain" do
    ahds = FactoryBot.build(:ad_hoc_domain_subject, ad_hoc_domain: nil)
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
      ad_hoc_domain: @ad_hoc_domain,
      subject: @subject)
    assert_not second.valid?    # Because it's the same as the first one
  end

  test "can be sorted" do
    subject1 = FactoryBot.create(:subject, name: "Charlie")
    subject2 = FactoryBot.create(:subject, name: "Able")
    subject3 = FactoryBot.create(:subject, name: "Baker")
    ahds1 = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain: @ad_hoc_domain,
                              subject: subject1)
    ahds2 = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain: @ad_hoc_domain,
                              subject: subject2)
    ahds3 = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain: @ad_hoc_domain,
                              subject: subject3)

    @ad_hoc_domain.reload
    assert_equal [subject2, subject3, subject1, @subject],
      @ad_hoc_domain.ad_hoc_domain_subjects.sort.map(&:subject)
  end

  test "subject can be assigned via element" do
    subject = FactoryBot.create(:subject, name: "Charlie")
    ahds = FactoryBot.create(:ad_hoc_domain_subject,
                              ad_hoc_domain: @ad_hoc_domain,
                              subject_element: subject.element)
    assert_equal subject, ahds.subject
  end

  test "can have staff" do
    assert @ad_hoc_domain_subject.respond_to? :staffs
    assert @ad_hoc_domain_subject.respond_to? :ad_hoc_domain_staffs
  end

end
