# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class UsersController < ApplicationController

  #
  #  A class whose sole job is to produce either "" or " active".
  #
  class Activator

    #
    #  "seek" should be a regex
    #
    def initialize(seek)
      @seek = seek
    end

    def test(string)
      @seek =~ string ? " active " : ""
    end
  end

  before_action :set_user, only: [:show, :edit, :update, :destroy]

  #
  #  And here's me thinking that at last I can use just:
  #
  #    autocomplete :user, :name, :full => true
  #
  #  but alas it still doesn't quite cut it.  I want "sim jam" to
  #  find "Simon James", and the standard generator doesn't seem
  #  to have an option to manage that.
  #
  def autocomplete_user_name
    term = params[:term].split(" ").join("%")
    users =
      User.where('name LIKE ?', "%#{term}%").order(:name).all
    render :json => users.map { |user| {:id => user.id, :label => user.name_with_email, :value => user.name} }
  end


  # 
  # Permissions pending.  A very brief request for the current number
  # of outstanding permissions for the current user.
  #
  def pp
    @pph = Hash.new
    if current_user
      @pph["pending-grand-total"]  = current_user.pending_grand_total
      @pph["pending-events-total"] = current_user.events_pending_total
      @pph["pending-my-events"]    = current_user.events_pending
      current_user.owned_concerns.each do |concern|
        @pph["pending-element-#{concern.element_id}".to_sym] =
        concern.permissions_pending
      end
    end
    respond_to do |format|
      format.json
    end
  end

  # GET /users
  # GET /users.json
  def index
    @user = User.new
    @user_profile = UserProfile.find_by(id: params[:user_profile_id])
    if @user_profile
      selector = @user_profile.users.order(:name)
    else
      selector = User.order(:name)
    end
    #
    #  If an explicit page has been requested then go to it.
    #  Otherwise check for other criteria.
    #
    page_param = params[:page]
    if page_param.blank?
      #
      #  Default to page 1.
      #
      page_param = "1"
      user_id = params[:user_id]
      unless user_id.blank?
        #
        #  Seem to want to jump to a particular user.
        #  Use find_by to avoid raising an error.
        #
        target_user = User.find_by(id: user_id)
        if target_user
          index = selector.find_index {|u| u.id == target_user.id}
          if index
            page_param = ((index / User.per_page) + 1).to_s
          end
        end
      end
    end
    @users = selector.page(page_param)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    if request.xhr?
      @minimal = true
      render :layout => false
    else
      @minimal = false
      render
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  #
  #   Three ways this can be accessed.
  #
  #   1. As a modal.  Regardless of whether or not you are an admin
  #      you get only minimal fields.
  #   2. As a full page.  You are meant to be an admin (in which
  #      case you get to set permission bits, and manipulate
  #      concerns), but if you are not an admin then...
  #   3. An ordinary user can access it as a full page, but only
  #      for his or her own user record.  The fields are the same
  #      as if it was a modal.
  #
  def edit
    if (current_user.admin? || current_user.id == @user.id)
      tt = DayShapeManager.template_type
      if tt
        @day_shapes = tt.rota_templates
      end
      if request.xhr?
        @modal = true
        @full_details = false
      else
        @modal = false
        @full_details = current_user.admin?
        if params[:edited_concern]
          @activator = Activator.new(/concerns/)
        else
          @activator = Activator.new(/general/)
        end
        @concern = Concern.new
      end
      render layout: !@modal
    else
      render :forbidden
    end
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    do_apply = params.has_key?(:apply)
    original_firstday = @user.firstday
    original_colour = @user.colour_not_involved
    original_day_shape_id = @user.day_shape_id
    respond_to do |format|
      if @user.update(user_params)
        @success = true
        @changed_display_options =
          (@user.firstday != original_firstday) ||
          (@user.colour_not_involved != original_colour) ||
          (@user.day_shape_id != original_day_shape_id)
        format.html do
          if do_apply
            redirect_to edit_user_path(@user)
          else
            redirect_to users_path({user_id: @user.id}),
                      notice: 'User was successfully updated.' 
          end
        end
        format.json { render :show, status: :ok, location: @user }
        format.js
      else
        @success = false
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      known_user? && (current_user.admin ||
                      action == 'edit' ||
                      action == 'update' ||
                      action == 'pp')
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      if current_user.admin
        params.require(:user).
               permit(:provider,
                      :uid,
                      :name,
                      :email,
                      :admin,
                      :editor,
                      :can_add_resources,
                      :can_add_notes,
                      :exams,
                      :edit_all_events,
                      :subedit_all_events,
                      :arranges_cover,
                      :secretary,
                      :privileged,
                      :public_groups,
                      :email_notification,
                      :immediate_notification,
                      :resource_clash_notification,
                      :loading_notification,
                      :confirmation_messages,
                      :prompt_for_forms,
                      :clash_weekly,
                      :clash_daily,
                      :clash_immediate,
                      :invig_weekly,
                      :invig_daily,
                      :can_has_groups,
                      :can_has_forms,
                      :can_find_free,
                      :can_add_concerns,
                      :can_su,
                      :can_roam,
                      :firstday,
                      :list_teachers,
                      :list_rooms,
                      :warn_no_resources,
                      :show_pre_requisites,
                      :preferred_event_category_id,
                      :colour_not_involved,
                      :default_event_text,
                      :day_shape_id,
                      :can_relocate_lessons,
                      :user_profile_id,
                      permissions: PermissionFlags.permitted_keys)
      elsif current_user.editor?
        params.require(:user).
               permit(:firstday,
                      :list_teachers,
                      :list_rooms,
                      :warn_no_resources,
                      :show_pre_requisites,
                      :email_notification,
                      :immediate_notification,
                      :resource_clash_notification,
                      :loading_notification,
                      :confirmation_messages,
                      :prompt_for_forms,
                      :clash_weekly,
                      :clash_daily,
                      :clash_immediate,
                      :invig_weekly,
                      :invig_daily,
                      :preferred_event_category_id,
                      :colour_not_involved,
                      :default_event_text,
                      :day_shape_id)
      else
        params.require(:user).
               permit(:firstday,
                      :list_teachers,
                      :list_rooms,
                      :warn_no_resources,
                      :show_pre_requisites,
                      :colour_not_involved,
                      :email_notification,
                      :immediate_notification,
                      :resource_clash_notification,
                      :loading_notification,
                      :confirmation_messages,
                      :prompt_for_forms,
                      :clash_weekly,
                      :clash_daily,
                      :clash_immediate,
                      :invig_weekly,
                      :invig_daily,
                      :day_shape_id)
      end
    end
end
