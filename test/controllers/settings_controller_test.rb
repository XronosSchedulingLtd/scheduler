require 'test_helper'

class SettingsControllerTest < ActionController::TestCase
  setup do
    @setting = settings(:one)
    session[:user_id] = users(:admin).id
    @fresh_era = FactoryBot.create(:era)
    assert_not_nil groups(:roomcovergroup).element
    @spare_group = FactoryBot.create(:group)
    @spare_category = FactoryBot.create(:eventcategory)
    @spare_day_shape = FactoryBot.create(:rota_template)
    @spare_property = FactoryBot.create(:property)
  end

  test "should show setting" do
    get :show, params: { id: @setting }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @setting }
    assert_response :success
    #
    #  And check all the fields have been correctly filled in.
    #
    check_text(:title_text)
    check_text(:public_title_text)
    check_selection(:current_era_id)
    check_selection(:previous_era_id)
    check_selection(:next_era_id)
    check_selection(:perpetual_era_id)
    check_checked(:enforce_permissions, true)
    check_text(:current_mis)
    check_text(:previous_mis)
    check_selection(:auth_type)
    check_text(:dns_domain_name)
    check_checked(:prefer_https, true)
    check_checked(:require_uuid, false)
    check_text(:from_email_address)
    check_text(:room_cover_group_element_name,
               elements(:roomcovergroupelement).name)
    check_text(:room_cover_group_element_id)
    check_text(:event_creation_markup)
    check_text(:wrapping_before_mins)
    check_text(:wrapping_after_mins)
    check_text(:wrapping_eventcategory_name,
               eventcategories(:eventsetup).name)
    check_text(:wrapping_eventcategory_id)
    check_selection(:default_display_day_shape_id)
    check_selection(:default_free_finder_day_shape_id)
    check_checked(:tutorgroups_by_house, true)
    check_checked(:ordinalize_years, true)
    check_text(:tutorgroups_name)
    check_text(:tutor_name)
    check_text(:prep_suffix)
    check_text(:prep_property_element_name,
               elements(:prepelement).name)
    check_text(:max_quick_buttons)
    check_selection(:first_tt_day)
    check_selection(:last_tt_day)
    check_text(:tt_cycle_weeks)
    check_text(:tt_prep_letter)
    check_text(:tt_store_start)
    check_text(:busy_string)
    check_text(:user_file_allowance)
    check_text(:email_keep_days)
    check_text(:zoom_link_text)
    check_text(:zoom_link_base_url)
    #
    #  Modifying the datepicker type has been disabled for now.  Not
    #  all the work to enable native datepickers has been done.
    #
#    check_selection(:datepicker_type)
    check_checkbox_collection(:ft_default_days, 7)
    check_text(:ft_default_num_days)
    check_text(:ft_default_day_starts_at)
    check_text(:ft_default_day_ends_at)
    check_text(:ft_default_duration)
  end

  test "can update all fields" do
    to_update = {
      title_text:                       "The Banana Bunch",
      public_title_text:                "Secret stuff",
      current_era_id:                   @fresh_era.id,
      previous_era_id:                  @fresh_era.id,
      next_era_id:                      @fresh_era.id,
      perpetual_era_id:                 @fresh_era.id,
      enforce_permissions:              false,
      current_mis:                      "Banana",
      previous_mis:                     "Banana",
      auth_type:                        "google_demo_auth",
      dns_domain_name:                  "scheduler.xronos.uk",
      prefer_https:                     false,
      require_uuid:                     true,
      from_email_address:               "john@myschool.org.uk",
      room_cover_group_element_id:      @spare_group.element.id,
      event_creation_markup:            "Hello world",
      wrapping_before_mins:             99,
      wrapping_after_mins:              150,
      wrapping_eventcategory_id:        @spare_category.id,
      default_display_day_shape_id:     @spare_day_shape.id,
      default_free_finder_day_shape_id: @spare_day_shape.id,
      tutorgroups_by_house:             false,
      ordinalize_years:                 false,
      tutorgroups_name:                 "Flipflop",
      tutor_name:                       "Magister",
      prep_suffix:                      "(H)",
      prep_property_element_id:         @spare_property.element.id,
      max_quick_buttons:                99,
      first_tt_day:                     4,
      last_tt_day:                      6,
      tt_cycle_weeks:                   1,
      tt_prep_letter:                   'G',
      tt_store_start:                   '01/02/2003',
      busy_string:                      'Go away',
      user_file_allowance:              999,
      email_keep_days:                  999,
      zoom_link_text:                   "Wheeeeee!",
      zoom_link_base_url:               "http://",
#      datepicker_type:                  "dp_native",
      ft_default_num_days:              12,
      ft_default_day_starts_at:         "09:00",
      ft_default_day_ends_at:           "19:00",
      ft_default_duration:              30
    }

    to_update.each do |key, value|
      update_field(key, value)
    end
  end

  private

  def update_field(field, new_value)
    #
    #  We are allowed only one Setting record in the database, and that
    #  one is a fixture in the test environment.  If we modify it then
    #  we risk affecting all the other tests, so we must undo all the
    #  changes which we make before we finish.
    #
    saved = @setting[field]
    assert_not_equal new_value, @setting[field]
    patch(
      :update,
      params: {
        id: @setting,
        setting: {
          field => new_value
        }
      }
    )
    assert_redirected_to setting_path(assigns(:setting))
    @setting.reload
    saved_value = @setting[field]
    if saved_value.instance_of? Date
      #
      #  By doing this we invoke our configured default formatting for
      #  dates and get DD/MM/YYYY
      #
      saved_value = saved_value.to_s
    elsif saved_value.instance_of? Tod::TimeOfDay
      saved_value = saved_value.strftime("%H:%M")
    end
    assert_equal new_value, saved_value
    @setting[field] = saved
    @setting.save
  end

  def check_text(field, contents = nil)
    unless contents
      stored = @setting[field]
      if stored.instance_of?(Tod::TimeOfDay)
        contents = stored.strftime("%H:%M:%S.%3N")
      else
        contents = stored.to_s
      end
    end
    assert_select "#setting_#{field}" do |fields|
      assert_equal 1, fields.count
      case fields.first.name
      when 'input'
        assert_equal contents, fields.first['value']
      when 'textarea'
        #
        #  The textarea may well contain additional leading and trailing
        #  whitespace, especially carriage returns.
        #
        assert_match /\s*#{contents}\s*/, fields.first.inner_html
      else
        raise ArgumentError.new("Can't handle text field of type #{fields.first.name}.")
      end
    end
  end

  def check_selection(field)
    assert_select "#setting_#{field}" do |fields|
      assert_equal 1, fields.count
      assert_select fields, 'option[@selected="selected"]' do |selected|
        assert_equal 1, selected.count
        assert_equal @setting[field].to_s, selected.first['value']
      end
    end
  end

  def check_checked(field, checked)
    assert_select "#setting_#{field}" do |fields|
      assert_equal 1, fields.count
      if checked
        assert_equal "checked", fields.first["checked"]
      else
        assert_nil fields.first["checked"]
      end
    end
  end

  def check_checkbox_collection(field, count)
    count.times do |i|
      checked = Setting.current[field].include?(i)
      check_checked("#{field}_#{i}", checked)
    end
  end


end
