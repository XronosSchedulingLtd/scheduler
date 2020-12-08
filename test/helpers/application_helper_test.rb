require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  #
  #  What we are doing here is actually testing an extension to
  #  Rails's ForBuilder code.  However, this seems as good a place
  #  to test it as any.
  #
  setup do
    @freefinder = Freefinder.new
  end

  teardown do
    #
    #  Various other tests assume this will be the default datepicker
    #  type.  We've been messing about with it so need to set it back.
    #
    #  Note that it's not enough for our last listed test to set it back
    #  because they can be executed in any order.
    #
    Setting.current.datepicker_type = :dp_jquery
  end

  test "can get basic native datepicker" do
    #
    #  This is slightly odd.  Normally, having modified the system
    #  settings we'd need to save the record and flush the cache.  However
    #  since this is running just as sequential code and the same
    #  cached copy will be used for subsequent calls, we can get away
    #  with just modifying it in memory.
    #
    Setting.current.datepicker_type = :dp_native
    form_for @freefinder do |f|
      result = f.configured_date_field(:on)
      assert_match /input/, result
      assert_match /type="date"/, result
      assert_no_match /class/, result
    end
  end

  test "can get basic native datepicker with class" do
    Setting.current.datepicker_type = :dp_native
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, class: :banana)
      assert_match /input/, result
      assert_match /type="date"/, result
      assert_match /class="banana"/, result
    end
  end

  test "can get basic native datepicker with two classes by array" do
    Setting.current.datepicker_type = :dp_native
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, class: [:banana, :fritter])
      assert_match /input/, result
      assert_match /type="date"/, result
      assert_match /class="banana fritter"/, result
    end
  end

  test "can get basic native datepicker with two classes by string" do
    Setting.current.datepicker_type = :dp_native
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, class: "banana fritter")
      assert_match /input/, result
      assert_match /type="date"/, result
      assert_match /class="banana fritter"/, result
    end
  end

  test "can get basic native datepicker with id" do
    Setting.current.datepicker_type = :dp_native
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, id: :banana)
      assert_match /input/, result
      assert_match /type="date"/, result
      assert_match /id="banana"/, result
    end
  end

  #
  #  And now the JQuery ones.
  #
  test "can get basic jquery datepicker" do
    Setting.current.datepicker_type = :dp_jquery
    form_for @freefinder do |f|
      result = f.configured_date_field(:on)
      assert_match /input/, result
      assert_match /type="text"/, result
      assert_match /class="datepicker"/, result
    end
  end

  test "can get basic jquery datepicker with class" do
    Setting.current.datepicker_type = :dp_jquery
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, class: :banana)
      assert_match /input/, result
      assert_match /type="text"/, result
      assert_match /class="banana datepicker"/, result
    end
  end

  test "can get basic jquery datepicker with two classes by array" do
    Setting.current.datepicker_type = :dp_jquery
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, class: [:banana, :fritter])
      assert_match /input/, result
      assert_match /type="text"/, result
      assert_match /class="banana fritter datepicker"/, result
    end
  end

  test "can get basic jquery datepicker with two classes by string" do
    Setting.current.datepicker_type = :dp_jquery
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, class: "banana fritter")
      assert_match /input/, result
      assert_match /type="text"/, result
      assert_match /class="banana fritter datepicker"/, result
    end
  end

  test "can get basic jquery datepicker with id" do
    Setting.current.datepicker_type = :dp_jquery
    form_for @freefinder do |f|
      result = f.configured_date_field(:on, id: :banana)
      assert_match /input/, result
      assert_match /type="text"/, result
      assert_match /class="datepicker"/, result
      assert_match /id="banana"/, result
    end
  end

end
