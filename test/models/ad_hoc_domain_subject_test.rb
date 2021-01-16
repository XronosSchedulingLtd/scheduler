require 'test_helper'

class AdHocDomainSubjectTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @ad_hoc_domain_subject =
      FactoryBot.create(
        :ad_hoc_domain_subject,
        ad_hoc_domain: @ad_hoc_domain,
        subject_element: @subject.element)
  end

  test "can be valid" do
    assert @ad_hoc_domain_subject.valid?
  end

  test "must have a domain" do
    ahds = FactoryBot.build(:ad_hoc_domain_subject, ad_hoc_domain: nil)
    assert_not ahds.valid?
  end

  test "must have a subject" do
    ahds = FactoryBot.build(:ad_hoc_domain_subject, subject_element: nil)
    assert_not ahds.valid?
  end

  test "must be unique" do
    second = FactoryBot.build(
      :ad_hoc_domain_subject,
      ad_hoc_domain: @ad_hoc_domain,
      subject_element: @subject.element)
    assert_not second.valid?    # Because it's the same as the first one
  end

  test "can have staff" do
  end

end
