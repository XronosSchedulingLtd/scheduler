# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user

  before_filter :login_required

  private

  def login_required
    authorized?  || access_denied
  end

  def access_denied
    respond_to do |format|
      format.html do
        redirect_to '/'
      end
      format.any(:json, :xml, :js) do
        redirect_to '/'
      end
    end
  end

  #
  #  All actions required admin privilege by default.  Override this method
  #  in the individual controller to lower the privilege requirements.
  #
  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.admin
  end

  def logged_in?
    !!current_user
  end

  def current_user
    @current_user ||=
      User.includes(:ownerships).find_by(id: session[:user_id]) if session[:user_id]
  end

end
