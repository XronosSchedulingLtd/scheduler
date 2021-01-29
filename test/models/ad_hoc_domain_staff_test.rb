require 'test_helper'

class AdHocDomainStaffTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @subject = FactoryBot.create(:subject)
    @staff = FactoryBot.create(:staff, surname: "ZZZ")
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
  end

  test "can be valid" do
    assert @ad_hoc_domain_staff.valid?
  end

  test "must have a subject" do
    ahds = FactoryBot.build(:ad_hoc_domain_staff, ad_hoc_domain_subject: nil)
    assert_not ahds.valid?
  end

  test "must have a staff" do
    ahds = FactoryBot.build(:ad_hoc_domain_staff, staff: nil)
    assert_not ahds.valid?
  end

  test "must be unique" do
    second = FactoryBot.build(
      :ad_hoc_domain_staff,
      staff: @staff,
      ad_hoc_domain_subject: @ad_hoc_domain_subject)
    assert_not second.valid?    # Because it's the same as the first one
  end

  test "staff can be assigned via element" do
    staff = FactoryBot.create(:staff, name: "Charlie")
    ahds = FactoryBot.create(:ad_hoc_domain_staff,
                              ad_hoc_domain_subject: @ad_hoc_domain_subject,
                              staff_element: staff.element)
    assert_equal staff, ahds.staff
  end

  test "can get staff name directly" do
    assert @ad_hoc_domain_staff.respond_to? :staff_name
    assert_equal @ad_hoc_domain_staff.staff.name,
      @ad_hoc_domain_staff.staff_name
  end

  test "can be sorted" do
    staff1 = FactoryBot.create(:staff, surname: "Charlie")
    staff2 = FactoryBot.create(:staff, surname: "Able")
    staff3 = FactoryBot.create(:staff, surname: "Baker")
    ahds1 = FactoryBot.create(:ad_hoc_domain_staff,
                              ad_hoc_domain_subject: @ad_hoc_domain_subject,
                              staff: staff1)
    ahds2 = FactoryBot.create(:ad_hoc_domain_staff,
                              ad_hoc_domain_subject: @ad_hoc_domain_subject,
                              staff: staff2)
    ahds3 = FactoryBot.create(:ad_hoc_domain_staff,
                              ad_hoc_domain_subject: @ad_hoc_domain_subject,
                              staff: staff3)

    @ad_hoc_domain.reload
    assert_equal [staff2, staff3, staff1, @staff],
      @ad_hoc_domain_subject.ad_hoc_domain_staffs.sort.map(&:staff)
  end

  test "can calculate loading" do
    assert @ad_hoc_domain_staff.respond_to? :loading
  end

end
