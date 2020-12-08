# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class DayName
  attr_reader :index, :name

  def initialize(index, name)
    @index = index
    @name = name
  end
end

class SettingsController < ApplicationController
  before_action :set_setting, only: [:show, :edit, :update]

  
  # GET /settings
  #
  def index
    @settings = Setting.all
  end

  # GET /settings/1
  # GET /settings/1.json
  def show
  end

  # GET /settings/1/edit
  def edit
    tt = DayShapeManager.template_type
    if tt
      @day_shapes = tt.rota_templates
    else
      @day_shapes = []
    end
    @day_names = Array.new
    Date::DAYNAMES.each_with_index do |dayname, index|
      @day_names << DayName.new(index, dayname)
    end
  end

  # PATCH/PUT /settings/1
  # PATCH/PUT /settings/1.json
  def update
    respond_to do |format|
      if @setting.update(setting_params)
        format.html { redirect_to @setting, notice: 'Setting was successfully updated.' }
        format.json { render :show, status: :ok, location: @setting }
      else
        format.html {
          #
          #  Call the edit method afresh to set up environment bits
          #
          edit()
          render :edit
        }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting
      @setting = Setting.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def setting_params
      params.require(:setting).
             permit(:title_text,
                    :public_title_text,
                    :current_era_id,
                    :next_era_id,
                    :previous_era_id,
                    :perpetual_era_id,
                    :enforce_permissions,
                    :current_mis,
                    :previous_mis,
                    :auth_type,
                    :dns_domain_name,
                    :from_email_address,
                    :prefer_https,
                    :require_uuid,
                    :room_cover_group_element_name,
                    :room_cover_group_element_id,
                    :event_creation_markup,
                    :wrapping_before_mins,
                    :wrapping_after_mins,
                    :wrapping_eventcategory_name,
                    :wrapping_eventcategory_id,
                    :default_display_day_shape_id,
                    :default_free_finder_day_shape_id,
                    :tutorgroups_by_house,
                    :tutorgroups_name,
                    :tutor_name,
                    :prep_suffix,
                    :ordinalize_years,
                    :prep_property_element_name,
                    :prep_property_element_id,
                    :max_quick_buttons,
                    :first_tt_day,
                    :last_tt_day,
                    :tt_cycle_weeks,
                    :tt_prep_letter,
                    :tt_store_start,
                    :busy_string,
                    :user_file_allowance,
                    :email_keep_days,
                    :event_keep_years,
                    :zoom_link_text,
                    :zoom_link_base_url,
                    :datepicker_type,
                    :ft_default_num_days,
                    :ft_default_day_starts_at,
                    :ft_default_day_ends_at,
                    :ft_default_duration,
                    ft_default_days: [])
    end
end
