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
    @ad_hoc_domain.subject_elements << subject1.element
    @ad_hoc_domain.subject_elements << subject2.element
    assert_equal 2, @ad_hoc_domain.subject_elements.count
    assert subject1.element.ad_hoc_domains_as_subject.include?(@ad_hoc_domain)
  end

end
