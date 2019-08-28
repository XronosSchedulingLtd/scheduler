# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class UserFilesController < ApplicationController

  prepend_before_action :set_user, only: [:upload]
  prepend_before_action :might_set_user, only: [:index]
  prepend_before_action :set_user_file, only: [:destroy]
  prepend_before_action :find_by_nanoid, only: [:show]

  #
  #  GET /users/1/user_files
  #
  def index
    #
    #  If no specific user has been specified, then use the current
    #  user.
    #
    #  However, if we are accessed as /user_files then the upload
    #  facility currently doesn't work, so disable it.
    #
    if @user
      might_allow_upload = true
    else
      @user = current_user
      might_allow_upload = false
    end
    if @user
      @user_files = @user.user_files.order(:original_file_name)
      if might_allow_upload
        @allow_upload, @total_size, @allowance = @user.can_upload_with_figures?
      else
        @allow_upload = false
        @total_size = 0
        @allowance = 0
      end
    else
      @user_files = []
      @allow_upload = false
      @total_size = 0
      @allowance = 0
    end
  end

  def show
    #
    #  @user_file should already be set.
    #
    #  Webrick gets marginally upset if we don't set the file
    #  size in the header for it.
    #
    if @user_file && @user_file.file_exists?
      response.headers['Content-Length'] = @user_file.file_size.to_s
      send_file(@user_file.file_full_path_name,
                filename: @user_file.original_file_name)
    else
      render 'file_not_found'
    end
  end

  #
  #  Receive an incoming file.
  #
  def upload
#    raise params.inspect
    file_info = params[:file_info]
    if file_info
      @user_file = @user.user_files.create({file_info: file_info})
      #
      #  Garbage collection should do this eventually anyway,
      #  but let's do it explicitly in case we get a lot hanging
      #  around.
      #
      file_info.close(true)
    end
    respond_to do |format|
      format.html { redirect_to user_user_files_path(@user) }
      format.js
    end
  end

  def destroy
    user = @user_file.owner
    @user_file.destroy
    redirect_to user_user_files_path(user)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:user_id])
  end

  #
  #  For an index, the user_id parameters is optional.
  #
  def might_set_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user = nil
    end
  end

  def set_user_file
    @user_file = UserFile.find(params[:id])
  end

  def find_by_nanoid
    #
    #  Use find_by! to make it behave like find and raise an error
    #  if the record is not found.
    #
    @user_file = UserFile.find_by(nanoid: params[:id])
  end

  def authorized?(action = action_name, resource = nil)
    if current_user
      case action
      when 'index'
        #
        #  A user may or may not have been specified.
        #
        Rails.logger.debug("admin flag yields #{current_user.admin?}")
        current_user.admin? ||
          (@user && current_user == @user) ||
          (!@user)
      when 'upload'
        current_user.admin? || current_user == @user
      when 'destroy'
        current_user.can_delete?(@user_file)
      when 'show'
        true
      else
        false
      end
    else
      #
      #  For guests, only 'show' is allowed.
      #
      action == 'show'
    end
  end

end

