#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class DatasourceTest < ActiveSupport::TestCase
  setup do
    @valid_params = {
      name: "This is a data source"
    }
  end

  test 'can create a datasource' do
    ds = Datasource.new(@valid_params)
    assert ds.valid?
  end

  test 'name is required' do
    ds = Datasource.new(@valid_params.except(:name))
    assert_not ds.valid?
  end

  test 'name must be unique' do
    ds1 = Datasource.create(@valid_params)
    assert ds1.valid?
    ds2 = Datasource.new(@valid_params)
    assert_not ds2.valid?
  end

  test 'can have staff members' do
    ds = Datasource.create(@valid_params)
    ds.staffs << staff1 = FactoryBot.create(:staff)
    ds.staffs << staff2 = FactoryBot.create(:staff)
    assert_equal 2, ds.staffs.count
    ds.destroy
    assert_not staff1.destroyed?
    assert_not staff2.destroyed?
    staff1.reload
    staff2.reload
    assert_nil staff1.datasource
    assert_nil staff2.datasource
  end

  test 'can have pupils' do
    ds = Datasource.create(@valid_params)
    ds.pupils << pupil1 = FactoryBot.create(:pupil)
    ds.pupils << pupil2 = FactoryBot.create(:pupil)
    assert_equal 2, ds.pupils.count
    ds.destroy
    assert_not pupil1.destroyed?
    assert_not pupil2.destroyed?
    pupil1.reload
    pupil2.reload
    assert_nil pupil1.datasource
    assert_nil pupil2.datasource
  end

  test 'can have locationaliases' do
    ds = Datasource.create(@valid_params)
    ds.locationaliases << locationalias1 = FactoryBot.create(:locationalias)
    ds.locationaliases << locationalias2 = FactoryBot.create(:locationalias)
    assert_equal 2, ds.locationaliases.count
    ds.destroy
    assert_not locationalias1.destroyed?
    assert_not locationalias2.destroyed?
    locationalias1.reload
    locationalias2.reload
    assert_nil locationalias1.datasource
    assert_nil locationalias2.datasource
  end

  test 'can have groups' do
    ds = Datasource.create(@valid_params)
    ds.groups << group1 = FactoryBot.create(:group)
    ds.groups << group2 = FactoryBot.create(:group)
    assert_equal 2, ds.groups.count
    ds.destroy
    assert_not group1.destroyed?
    assert_not group2.destroyed?
    group1.reload
    group2.reload
    assert_nil group1.datasource
    assert_nil group2.datasource
  end

  test 'can have subjects' do
    ds = Datasource.create(@valid_params)
    ds.subjects << subject1 = FactoryBot.create(:subject)
    ds.subjects << subject2 = FactoryBot.create(:subject)
    assert_equal 2, ds.subjects.count
    ds.destroy
    assert_not subject1.destroyed?
    assert_not subject2.destroyed?
    subject1.reload
    subject2.reload
    assert_nil subject1.datasource
    assert_nil subject2.datasource
  end

  test 'sorts by name' do
    datasources = Array.new
    datasources << ds1 = Datasource.create(@valid_params.merge({name: "Zak"}))
    datasources << ds2 = Datasource.create(@valid_params.merge({name: "Able"}))
    datasources << ds3 = Datasource.create(@valid_params.merge({name: "Baker"}))
    sorted = datasources.sort
    assert_equal ds2, sorted[0]
    assert_equal ds3, sorted[1]
    assert_equal ds1, sorted[2]
  end

  test 'prevent destruction if pupils' do
    ds = Datasource.create(@valid_params)
    assert ds.can_destroy?
    ds.pupils << pupil1 = FactoryBot.create(:pupil)
    assert_not ds.can_destroy?
  end

  test 'prevent destruction if staff' do
    ds = Datasource.create(@valid_params)
    assert ds.can_destroy?
    ds.staffs << staff1 = FactoryBot.create(:staff)
    assert_not ds.can_destroy?
  end

end
