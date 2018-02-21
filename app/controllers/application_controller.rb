# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user,
                :user_can_roam?,
                :user_can_drag?,
                :admin_user?,
                :known_user?,
                :public_groups_user?

  before_filter :login_required

  private

  def login_required
    authorized?  || access_denied
  end

  def access_denied
    #
    #  New method of working, with different behaviour depending on the
    #  problem.
    #
    #  If a user is logged in and tries to access something unauthorized,
    #  then said user is re-directed to the home page.
    #
    #  If the user is *not* logged in, then we remember what page
    #  was being attempted, and re-direct to the login page.
    #
    #  If the login later completes successfully, we look to see whether
    #  we have a stored intended page, and then forward the user on there.
    #  Of course, the user may still not be authorised, but he or she is
    #  now logged on (because the loging completed successfully) and
    #  therefore will be directed to the home page - no infinite loop.
    #
    #  All of this happens only for HTML requests.  Need to do some
    #  better processing for json, xml and js.
    #
    respond_to do |format|
      format.html do
        if logged_in?
          redirect_to '/'
        else
          session[:url_requested] = request.fullpath
          redirect_to sessions_new_url
        end
      end
      #
      #  It appears that I should return one of two error codes for the
      #  other requests.  If the user is not logged in then they should
      #  get 401 Unauthenticated, whilst if they are logged in then the
      #  error is 403 Forbidden.
      #
      format.any(:json, :xml, :js) do
        redirect_to '/'
      end
    end
  end

  def current_user
    @current_user ||=
      User.includes(:concerns).find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  #
  #  All actions required admin privilege by default.  Override this method
  #  in the individual controller to lower the privilege requirements.
  #
  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.admin
  end

  #
  #  These are for quickly checking particular privileges of the current
  #  user, taking account of the fact that there might not be a currently
  #  logged on user.
  #
  def user_can_roam?
    current_user && current_user.can_roam
  end

  def admin_user?
    current_user && current_user.admin?
  end

  def known_user?
    current_user && current_user.known?
  end

  def public_groups_user?
    current_user && current_user.public_groups?
  end

  def relocating_user?
    current_user && current_user.can_relocate_lessons?
  end

  def user_can_drag?(concern)
    current_user && current_user.can_drag?(concern)
  end

end
