class SessionsController < ApplicationController
  def new
#    Rails.logger.debug("Full path is #{request.fullpath}")
    #
    #  Want to guard agains left-over deep linking stuff.  If the user
    #  previously tried to access a page which triggered a login attempt,
    #  but they didn't complete the login, and have now chosen to do
    #  an explicit login, then they will be surprised if we go on to send
    #  them to the page they asked for earlier.  Guard against that
    #  case.
    #
    if /signin$/ =~ request.fullpath
      #
      #  This is an explicit login attempt.  Scrub any previous
      #  redirection information.
      #
      session.delete(:url_requested)
    end
    redirect_to '/auth/google_oauth2'
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by(provider: auth["provider"],
                        uid:      auth["uid"])
    if user
      unless user.known?
        #
        #  If a user is not known, we check each time to see whether
        #  he or she has become known.
        #
        user.find_matching_resources
      end
    else
      user = User.create_from_omniauth(auth)
    end
    url_requested = session[:url_requested]
    reset_session
    session[:user_id] = user.id
    Rails.logger.info("User #{user.email} signed in.")
    redirect_to url_requested || root_url, :notice => "Signed in"
  end

  #
  #  Allow direct login on demo systems.  For this to work:
  #
  #  1. System must be configured in demo mode.
  #  2. A user id must be specified.
  #  3. The user must exist.
  #  4. The user must be flagged as a demo user.
  #
  def demo_login
    if Setting.demo_system? && params[:user_id] &&
      (user = User.find_by(id: params[:user_id])) &&
      (user.demo_user?)
      reset_session
      session[:user_id] = user.id
      Rails.logger.info("User #{user.email} signed in (demo mode).")
    end
    redirect_to root_url
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    redirect_to root_url, :notice => "Signed out"
  end

  def failure
    #
    #  Could do with some info.
    #
    Rails.logger.debug("Login failed")
    Rails.logger.debug(request.env["omniauth.auth"].inspect)
    redirect_to root_url, :notice => "Login failed"
  end

  #
  #  A request to change the user id for this session.
  #
  def become
    #
    #  We need permission, and we can't do nested su.
    #
    if user_can_su?
      user_id = params[:user_id]
      if user_id && user_id.to_i != current_user.id
        new_user = User.find_by(id: user_id)
        if new_user
          original_user = current_user
          reset_session
          @current_user = nil
          session[:user_id] = new_user.id
          session[:original_user_id] = original_user.id
          Rails.logger.info("User #{original_user.email} su'ed to #{new_user.email}.")
        end
      end
    end
    redirect_to :root
  end

  #
  #  A request to go back to the previous user id after an su
  #  Note that we can only go back by one.
  #
  def revert
    original_user_id = session[:original_user_id]
    if original_user_id
      #
      #  The request to revert does at least have some meaning.
      #
      reset_session
      @current_user = nil
      session[:user_id] = original_user_id
    end
    redirect_to :root
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? ||
      action == 'new' ||
      action == 'create' ||
      action == 'failure' ||
      action == 'demo_login'
  end

end
