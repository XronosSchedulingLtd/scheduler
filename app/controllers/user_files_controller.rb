# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class UserFilesController < ApplicationController

  prepend_before_action :set_user, only: [:index, :upload]
  prepend_before_action :set_user_file, only: [:destroy]
  prepend_before_action :find_by_uuid, only: [:show]

  #
  #  GET /users/1/user_files
  #
  def index
    @user_files = @user.user_files
    @allow_upload, @total_size, @allowance = @user.can_upload_with_figures?
  end

  def show
    #
    #  @user_file should already be set.
    #
    send_file(@user_file.file_full_path_name,
              filename: @user_file.original_file_name)
  end

  #
  #  Receive an incoming file.
  #
  def upload
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
    redirect_to user_user_files_path(@user)
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

  def set_user_file
    @user_file = UserFile.find(params[:id])
  end

  def find_by_uuid
    #
    #  Use find_by! to make it behave like find and raise an error
    #  if the record is not found.
    #
    @user_file = UserFile.find_by!(uuid: params[:id])
  end

  def authorized?(action = action_name, resource = nil)
    if known_user?
      case action
      when 'index', 'upload'
        current_user.admin? || current_user == @user
      when 'destroy'
        current_user.admin? || current_user == @user_file.owner
      when 'show'
        true
      else
        false
      end
    else
      false
    end
  end

end

