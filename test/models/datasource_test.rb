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

  test "can create a datasource" do
    ds = Datasource.new(@valid_params)
    assert ds.valid?
  end

  test "name is required" do
    ds = Datasource.new(@valid_params.except(:name))
    assert_not ds.valid?
  end

  test "name must be unique" do
    ds1 = Datasource.create(@valid_params)
    assert ds1.valid?
    ds2 = Datasource.new(@valid_params)
    assert_not ds2.valid?
  end

end
