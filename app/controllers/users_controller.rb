# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class UsersController < ApplicationController
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
    if current_user && current_user.element_owner
      @pph[:pp] = current_user.permissions_pending
    else
      @pph[:pp] = 0
    end
    respond_to do |format|
      format.json
    end
  end

  # GET /users
  # GET /users.json
  def index
    @user = User.new
    selector = User.order(:name)
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
  def edit
    if current_user.known? &&
       (current_user.admin || current_user.id == @user.id)
      tt = DayShapeManager.template_type
      if tt
        @day_shapes = tt.rota_templates
      end
      if request.xhr?
        @minimal = true
        render :layout => false
      else
        @minimal = false
        render
      end
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
        format.html { redirect_to users_path({user_id: @user.id}), notice: 'User was successfully updated.' }
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
      logged_in? && (current_user.admin ||
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
                      :exams,
                      :edit_all_events,
                      :subedit_all_events,
                      :arranges_cover,
                      :secretary,
                      :privileged,
                      :public_groups,
                      :email_notification,
                      :immediate_notification,
                      :clash_weekly,
                      :clash_daily,
                      :clash_immediate,
                      :invig_weekly,
                      :invig_daily,
                      :can_has_groups,
                      :can_find_free,
                      :can_add_concerns,
                      :can_su,
                      :can_roam,
                      :firstday,
                      :list_teachers,
                      :warn_no_resources,
                      :preferred_event_category_id,
                      :colour_not_involved,
                      :default_event_text,
                      :day_shape_id)
      elsif current_user.editor
        params.require(:user).
               permit(:firstday,
                      :list_teachers,
                      :warn_no_resources,
                      :email_notification,
                      :immediate_notification,
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
                      :warn_no_resources,
                      :colour_not_involved,
                      :email_notification,
                      :immediate_notification,
                      :clash_weekly,
                      :clash_daily,
                      :clash_immediate,
                      :invig_weekly,
                      :invig_daily,
                      :day_shape_id)
      end
    end
end
