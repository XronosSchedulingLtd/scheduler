require 'test_helper'

class AdHocDomainTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @user1 = FactoryBot.create(:user)
    @user2 = FactoryBot.create(:user)
    @day_shape =
      FactoryBot.create(:rota_template,
                        rota_template_type: rota_template_types(:dayshape))
  end

  test "can have a name" do
    assert @ad_hoc_domain.respond_to?(:name)
  end

  test "must have a name" do
    bad_domain = FactoryBot.build(:ad_hoc_domain, name: nil)
    assert_not bad_domain.valid?
  end

  test "must have an event category" do
    ahd = FactoryBot.build(:ad_hoc_domain, eventcategory: nil)
    assert_not ahd.valid?
  end

  test "must have an event source" do
    ahd = FactoryBot.build(:ad_hoc_domain, eventsource: nil)
    assert_not ahd.valid?
  end

  test "can have a data source but not compulsory" do
    ahd = FactoryBot.build(:ad_hoc_domain, datasource: nil)
    assert ahd.valid?
    ahd = FactoryBot.build(:ad_hoc_domain, datasource: datasources(:one))
    assert ahd.valid?
    
  end

  test "need not have a connected property" do
    ahd = FactoryBot.build(:ad_hoc_domain, connected_property_element: nil)
    assert ahd.valid?
  end

  test "can have a controller" do
    @ad_hoc_domain.controllers << @user1
    assert_equal 1, @ad_hoc_domain.controllers.count
    assert_equal 1, @user1.ad_hoc_domains.count
  end

  test "can list controllers" do
    @ad_hoc_domain.controllers << @user1
    @ad_hoc_domain.controllers << @user2
#    expected = [@user1, @user2].sort.collect {|u| u.name}.join(", ")
    expected = [@user1, @user2].sort.map(&:name).join(", ")
    assert_equal expected, @ad_hoc_domain.controller_list
  end

  test "can have a default day shape" do
    ahd = FactoryBot.build(:ad_hoc_domain, default_day_shape: @day_shape)
    assert ahd.valid?
    ahd.save!
    assert ahd.default_day_shape.ad_hoc_domain_defaults.include?(ahd)
  end

  test "can be linked to multiple subjects" do
    subject1 = FactoryBot.create(:subject)
    subject2 = FactoryBot.create(:subject)
    #
    #  Something intriguing which I discovered entirely by accident.
    #  I originally had a HABTM relationship between AdHocDomain and
    #  Subject Element, then changed it to an explicit intermediate
    #  model.  Nonetheless, the trick of <<ing a new element still
    #  seems to work.  Clever.
    #
    @ad_hoc_domain.subject_elements << subject1.element
    @ad_hoc_domain.subject_elements << subject2.element
    assert_equal 2, @ad_hoc_domain.subject_elements.count
    assert_equal 2, @ad_hoc_domain.ad_hoc_domain_subjects.count
    assert subject1.element.ad_hoc_domains_as_subject.include?(@ad_hoc_domain)
    #
    #  Deleting the AdHocDomain deletes its AdHocDomainSubjects but not
    #  the subjects.
    #
    assert_difference('AdHocDomainSubject.count', -2) do
      @ad_hoc_domain.destroy
      subject1.reload
      subject2.reload
      assert_not_nil subject1.element
      assert_not_nil subject2.element
    end
  end

  test "can be linked to multiple staff" do
    subject1 = FactoryBot.create(:subject)
    staff1 = FactoryBot.create(:staff)
    staff2 = FactoryBot.create(:staff)
    @ad_hoc_domain.subject_elements << subject1.element
    ahds = @ad_hoc_domain.ad_hoc_domain_subjects[0]
    #
    #  Can't use the << trick for AdHocDomainStaffs because more
    #  info needed.
    #
    @ad_hoc_domain.ad_hoc_domain_staffs.create(
      staff_element: staff1.element,
      ad_hoc_domain_subject: ahds
    )
    @ad_hoc_domain.ad_hoc_domain_staffs.create(
      staff_element: staff2.element,
      ad_hoc_domain_subject: ahds
    )
    assert_equal 1, @ad_hoc_domain.subject_elements.count
    assert_equal 1, @ad_hoc_domain.ad_hoc_domain_subjects.count
    assert_equal 2, @ad_hoc_domain.staff_elements.count
    assert_equal 2, @ad_hoc_domain.ad_hoc_domain_staffs.count
    assert staff1.element.ad_hoc_domains_as_staff.include?(@ad_hoc_domain)
    assert_difference('AdHocDomainStaff.count', -2) do
      @ad_hoc_domain.destroy
      staff1.reload
      staff2.reload
      assert_not_nil staff1.element
      assert_not_nil staff2.element
    end
  end

end
