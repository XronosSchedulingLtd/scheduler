require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  setup do
    @location1 = FactoryBot.create(:location, name: "Location 1")
    @inactive_location = FactoryBot.create(:location, active: false)
  end

  test "creating an active location should create an element" do
    location = Location.create(name: "Googol", active: true)
    assert_not_nil location.element
  end

  test "creating an inactive location should not create an element" do
    location = Location.create(name: "Googol", active: false)
    assert_nil location.element
  end

  test "changing location to active should create element" do
    assert_nil @inactive_location.element
    @inactive_location.active = true
    @inactive_location.save!
    assert_not_nil @inactive_location.element
  end

  test "modifying location name should change element name" do
    org_name = @location1.element.name
    @location1.name = "Banana"
    @location1.save
    assert_not_equal org_name, @location1.element.name
  end

  test "must have a name" do
    @location1.name = nil
    assert_not @location1.valid?
  end

  test "must have a non-blank name" do
    @location1.name = ""
    assert_not @location1.valid?
  end

  test "number of invigilators defaults to one" do
    assert_equal 1, @location1.num_invigilators
  end

  test "must have a number of invigilators" do
    location = Location.create(name: "Googol", num_invigilators: nil)
    assert_not location.valid?
  end

  test "each location has a weighting (default 100)" do
    assert_equal 100, @location1.weighting
  end

  test "weighting must be present" do
    @location1.weighting = nil
    assert_not @location1.valid?
  end

  test "weighting must be numerical" do
    @location1.weighting = "fred"
    assert_not @location1.valid?
  end

  test "can't be subsidiary to itself" do
    @location1.subsidiary_to = @location1
    assert_not @location1.valid?
  end

  test "can't have a subsidiary loop" do
    location2 = FactoryBot.create(:location,
                                  name: "Location 2",
                                  subsidiary_to: @location1)
    assert location2.valid?
    assert location2.subsidiary?
    location3 = FactoryBot.create(:location,
                                  name: "Location 3",
                                  subsidiary_to: location2)
    assert location3.valid?
    assert location3.subsidiary?
    @location1.subsidiary_to = location3
    assert_not @location1.valid?
  end

  test "deleting superior removes subsidiarity" do
    location2 = FactoryBot.create(:location,
                                  name: "Location 2",
                                  subsidiary_to: @location1)
    assert location2.valid?
    assert location2.subsidiary?
    @location1.destroy
    location2.reload
    assert location2.valid?
    assert_not location2.subsidiary?
  end

  test "superiors method returns correct list" do
    location2 = FactoryBot.create(:location,
                                  name: "Location 2",
                                  subsidiary_to: @location1)
    assert location2.valid?
    assert location2.subsidiary?
    location3 = FactoryBot.create(:location,
                                  name: "Location 3",
                                  subsidiary_to: location2)
    assert location3.valid?
    assert location3.subsidiary?
    superiors = location3.superiors
    assert_not superiors.include?(location3)
    assert superiors.include?(location2)
    assert superiors.include?(@location1)
  end


end
