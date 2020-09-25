require 'test_helper'

class AdHocDomainTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain = FactoryBot.create(:ad_hoc_domain)
    @user1 = FactoryBot.create(:user)
    @user2 = FactoryBot.create(:user)
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
end
