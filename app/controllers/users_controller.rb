# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.page(params[:page]).order('id')
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
    respond_to do |format|
      if @user.update(user_params)
        @success = true
        @changed_firstday = (@user.firstday != original_firstday)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
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
                     action == 'update')
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
                      :arranges_cover,
                      :secretary,
                      :privileged,
                      :public_groups,
                      :firstday,
                      :preferred_event_category_id,
                      :default_event_text)
      elsif current_user.editor
        params.require(:user).
               permit(:firstday,
                      :preferred_event_category_id,
                      :default_event_text)
      else
        params.require(:user).
               permit(:firstday)
      end
    end
end
