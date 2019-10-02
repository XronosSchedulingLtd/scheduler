# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user,
                :user_can_roam?,
                :user_can_drag?,
                :user_can_view_forms?,
                :user_can_su?,
                :user_can_revert?,
                :admin_user?,
                :known_user?,
                :public_groups_user?

  before_action :login_required

  private

  def back_or(fallback_location)
    session[:go_back_to] || fallback_location
  end

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
    current_user && current_user.known? && current_user.can_roam
  end

  def admin_user?
    current_user && current_user.known? && current_user.admin?
  end

  def known_user?
    current_user && current_user.known?
  end

  def public_groups_user?
    current_user && current_user.known? && current_user.public_groups?
  end

  def relocating_user?
    current_user && current_user.known? && current_user.can_relocate_lessons?
  end

  def user_can_drag?(concern)
    current_user && current_user.known? && current_user.can_drag?(concern)
  end

  def user_can_view_forms?
    current_user && current_user.known? && current_user.can_view_forms?
  end

  #
  #  Can only su if a) have permission and b) not already su'ed.
  #
  def user_can_su?
    current_user &&
      current_user.known? &&
      current_user.can_su? &&
      !session[:original_user_id]
  end

  def user_can_revert?
    !!session[:original_user_id]
  end

  #
  #  To calculate the appropriate permissions status for a new
  #  commitment being created by the current user.
  #
  def set_appropriate_approval_status(commitment)
    #
    #  It's just possible that we will be passed nil for the element
    #  (if someone is trying to create a gash commitment).  Rather
    #  than raising an exception, return uncontrolled.
    #
    #  The saving of the commitment will fail due to the
    #  lack of an element.
    #
    if commitment.element
      if current_user.needs_permission_for?(commitment.element)
        commitment.status = :requested
      else
        commitment.status = :uncontrolled
      end
    else
      commitment.status = :uncontrolled
    end
  end
end
